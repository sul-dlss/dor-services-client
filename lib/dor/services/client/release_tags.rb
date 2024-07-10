# frozen_string_literal: true

module Dor
  module Services
    class Client
      # Interact with release tags endpoint for a given object
      class ReleaseTags < VersionedService
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Create a release tag for an object
        #
        # @param tag [ReleaseTag]
        # @return [Boolean] true if successful
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        def create(tag:)
          resp = connection.post do |req|
            req.url "#{api_version}/objects/#{object_identifier}/release_tags"
            req.headers['Content-Type'] = 'application/json'
            req.body = tag.to_json
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          true
        end

        # List release tags for an object
        #
        # @param public [Boolean] indicates if we only want public release tags (defaults to false)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return [Array<ReleaseTag>]
        def list(public: false)
          url = "#{api_version}/objects/#{object_identifier}/release_tags"
          resp = connection.get(url, { public: public })

          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          JSON.parse(resp.body).map { |tag_data| ReleaseTag.new(tag_data) }
        end

        private

        attr_reader :object_identifier
      end
    end
  end
end
