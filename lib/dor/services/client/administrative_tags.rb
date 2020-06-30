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
        #
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

        # Replaces one or more administrative tags for an object
        #
        # @param tags [Array<String>]
        # @return [Boolean] true if successful
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        def replace(tags:)
          resp = connection.post do |req|
            req.url "#{api_version}/objects/#{object_identifier}/administrative_tags"
            req.headers['Content-Type'] = 'application/json'
            req.body = { administrative_tags: tags, replace: true }.to_json
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          true
        end

        # List administrative tags for an object
        #
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return [Array<String>]
        def list
          resp = connection.get do |req|
            req.url "#{api_version}/objects/#{object_identifier}/administrative_tags"
          end

          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          JSON.parse(resp.body)
        end

        # Updates an administrative tag for an object
        #
        # @param current [String] current tag to update
        # @param new [String] new tag to replace current tag
        # @return [Boolean] true if successful
        # @raise [NotFoundResponse] when the response is a 404 (object or current tag not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        def update(current:, new:)
          resp = connection.put do |req|
            req.url "#{api_version}/objects/#{object_identifier}/administrative_tags/#{CGI.escape(current)}"
            req.headers['Content-Type'] = 'application/json'
            req.body = { administrative_tag: new }.to_json
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          true
        end

        # Destroys an administrative tag for an object
        #
        # @param tag [String] a tag to destroy
        # @return [Boolean] true if successful
        # @raise [NotFoundResponse] when the response is a 404 (object or current tag not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        def destroy(tag:)
          resp = connection.delete do |req|
            req.url "#{api_version}/objects/#{object_identifier}/administrative_tags/#{CGI.escape(tag)}"
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          true
        end

        private

        attr_reader :object_identifier
      end
    end
  end
end
