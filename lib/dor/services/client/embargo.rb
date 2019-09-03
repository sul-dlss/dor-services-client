# frozen_string_literal: tru

module Dor
  module Services
    class Client
      # API calls that are about managing embargo on a repository object
      class Embargo < VersionedService
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # @param [String] embargo_date The date to update the embargo to (ISO 8601)
        # @param [String] requesting_user Who is making this change.
        #
        # @example
        #   client.update(embargo_date: '2099-10-20', requesting_user: 'jane')
        #
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        #
        # @return [NilClass] when the update is successful
        def update(embargo_date:, requesting_user:)
          resp = connection.patch do |req|
            req.url path
            req.headers['Content-Type'] = 'application/json'
            req.body = {
              embargo_date: embargo_date,
              requesting_user: requesting_user
            }.to_json
          end
          return if resp.success?

          raise UnexpectedResponse, ResponseErrorFormatter.format(response: resp, object_identifier: object_identifier)
        end

        private

        attr_reader :object_identifier

        def path
          "#{api_version}/objects/#{object_identifier}/embargo"
        end
      end
    end
  end
end
