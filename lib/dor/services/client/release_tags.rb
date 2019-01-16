# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about a repository object
      class ReleaseTags < VersionedService
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Creates a new release tag for the object
        # @param release [Boolean]
        # @param what [String]
        # @param to [String]
        # @param who [String]
        # @raises [UnexpectedResponse] if the request is unsuccessful.
        # @return [Boolean] true if successful
        # rubocop:disable Metrics/MethodLength
        def create(release:, what:, to:, who:)
          params = {
            to: to,
            who: who,
            what: what,
            release: release
          }
          resp = connection.post do |req|
            req.url "#{api_version}/objects/#{object_identifier}/release_tags"
            req.headers['Content-Type'] = 'application/json'
            req.body = params.to_json
          end
          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?

          true
        end
        # rubocop:enable Metrics/MethodLength

        private

        attr_reader :object_identifier
      end
    end
  end
end
