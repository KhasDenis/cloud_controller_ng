require 'messages/base_message'
require 'messages/validators'

module VCAP::CloudController
  class ResourceMatchCreateMessage < BaseMessage
    register_allowed_keys [:resources]

    validates :resources, array: true, length: {
      maximum: 5000,
      too_long: 'is too many (maximum is %{count} resources)',
      minimum: 1,
      too_short: 'must have at least %{count} resource'
    }
    validate :each_resource

    def self.from_v2_fingerprints(body)
      v3_body = {
        'resources' => MultiJson.load(body.string).map do |r|
          {
            'size_in_bytes' => r['size'],
            'checksum' => { 'value' => r['sha1'] },
            'path' => r['fn'],
            'mode' => r['mode']
          }
        end
      }
      new(v3_body)
    end

    def v2_fingerprints_body
      v2_fingerprints = resources.map do |resource|
        {
          sha1: resource[:checksum][:value],
          size: resource[:size_in_bytes],
          fn: resource[:path],
          mode: resource[:mode]
        }
      end

      StringIO.new(v2_fingerprints.to_json)
    end

    private

    def each_resource
      if resources.is_a?(Array)
        resources.each do |r|
          checksum_validator(r[:checksum])
          size_validator(r[:size_in_bytes])
        end
      end
    end

    RESOURCE_ERROR_PREAMBLE = 'array contains at least one resource with a'.freeze

    def checksum_validator(checksum)
      unless checksum.is_a?(Hash)
        errors.add(:resources, "#{RESOURCE_ERROR_PREAMBLE} non-object checksum") unless errors.added?(
          :resources, "#{RESOURCE_ERROR_PREAMBLE} non-object checksum"
        )
        return
      end

      unless checksum[:value].is_a?(String)
        errors.add(:resources, "#{RESOURCE_ERROR_PREAMBLE} non-string checksum value") unless errors.added?(
          :resources, "#{RESOURCE_ERROR_PREAMBLE} non-string checksum value"
        )
        return
      end

      unless valid_sha1?(checksum[:value])
        errors.add(:resources, "#{RESOURCE_ERROR_PREAMBLE} non-SHA1 checksum value") unless errors.added?(
          :resources, "#{RESOURCE_ERROR_PREAMBLE} non-SHA1 checksum value"
        )
        return
      end
    end

    def size_validator(size)
      unless size.is_a?(Integer)
        errors.add(:resources, "#{RESOURCE_ERROR_PREAMBLE} non-integer size_in_bytes") unless errors.added?(
          :resources, "#{RESOURCE_ERROR_PREAMBLE} non-integer size_in_bytes"
        )
        return
      end

      unless size >= 0
        errors.add(:resources, "#{RESOURCE_ERROR_PREAMBLE} negative size_in_bytes") unless errors.added?(
          :resources, "#{RESOURCE_ERROR_PREAMBLE} negative size_in_bytes"
        )
        return
      end
    end

    def valid_sha1?(value)
      value.length == VCAP::CloudController::ResourcePool::VALID_SHA_LENGTH
    end
  end
end