# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API call that queries the members of a collection.
      class Members < VersionedService
        Member = Struct.new(:externalIdentifier, :version, keyword_init: true)

        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Get a list of the members.
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return [Array<Member>]
        def members
          resp = connection.get do |req|
            req.url members_path
          end

          return response_to_models(resp) if resp.success?

          raise_exception_based_on_response!(resp, object_identifier)
        end

        private

        def response_to_models(resp)
          JSON.parse(resp.body)['members'].map { |result| Member.new(**result.symbolize_keys) }
        end

        def object_path
          "#{api_version}/objects/#{object_identifier}"
        end

        def members_path
          "#{object_path}/members"
        end

        attr_reader :object_identifier
      end
    end
  end
end
