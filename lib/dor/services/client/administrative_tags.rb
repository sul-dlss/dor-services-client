# frozen_string_literal: true

module Dor
  module Services
    class Client
      # Interact with administrative tags endpoint for a given object
      class AdministrativeTags < VersionedService
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Creates one or more administrative tags for an object
        # @param tags [Array<String>]
        # @return [Boolean] true if successful
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        def create(tags:)
          resp = connection.post do |req|
            req.url "#{api_version}/objects/#{object_identifier}/administrative_tags"
            req.headers['Content-Type'] = 'application/json'
            req.body = { administrative_tags: tags }.to_json
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          true
        end

        # List administrative tags for an object
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return [Hash]
        def list
          resp = connection.get do |req|
            req.url "#{api_version}/objects/#{object_identifier}/administrative_tags"
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
