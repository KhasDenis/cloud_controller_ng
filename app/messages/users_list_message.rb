require 'messages/metadata_list_message'

module VCAP::CloudController
  class UsersListMessage < MetadataListMessage
    register_allowed_keys [:guids, :usernames, :origins]

    validates_with NoAdditionalParamsValidator

    validate :origin_requires_username

    validates :guids, allow_nil: true, array: true
    validates :usernames, allow_nil: true, array: true
    validates :origins, allow_nil: true, array: true

    def self.from_params(params)
      super(params, %w(guids usernames origins))
    end

    def origin_requires_username
      if @origins
        unless @usernames
          errors.add(:origins, 'filter cannot be provided without usernames filter.')
        end
      end
    end
  end
end
