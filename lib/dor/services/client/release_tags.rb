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
        # @return [Boolean] true if successful
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
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
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          true
        end
        # rubocop:enable Metrics/MethodLength

        # List new release tags for the object
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return [Hash] (see Dor::ReleaseTags::IdentityMetadata.released_for)
        def list
          resp = connection.get do |req|
            req.url "#{api_version}/objects/#{object_identifier}/release_tags"
          end

          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          JSON.parse(resp.body)
        end

        private

        attr_reader :object_identifier
      end
    end
  end
end
