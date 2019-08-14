# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about versions
      class ObjectVersion < VersionedService
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Get the current version for a DOR object. This comes from Dor::VersionMetadataDS
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [String] the version identifier
        def current
          resp = connection.get do |req|
            req.url "#{object_path}/versions/current"
          end
          return resp.body if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Determines if a new version can be opened for a DOR object.
        # @param params [Hash] optional params (see dor-services-app)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [Boolean] true if a new version can be opened
        # rubocop:disable Metrics/MethodLength
        def openable?(**params)
          resp = connection.get do |req|
            # TODO: correct the typo below once
            #       https://github.com/sul-dlss/dor-services-app/issues/322 is
            #       merged and all running DSA instances have been deployed
            req.url "#{object_path}/versions/openeable"
            req.params = params
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          if resp.body == 'true'
            true
          elsif resp.body == 'false'
            false
          else
            raise MalformedResponse, "Expected true or false, not #{resp.body}"
          end
        end
        # rubocop:enable Metrics/MethodLength

        # Open new version for an object
        # @param params [Hash] optional params (see dor-services-app)
        # @raise [MalformedResponse] when the response is not parseable.
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [String] the current version
        def open(**params)
          version = open_new_version_response(**params)
          raise MalformedResponse, "Version of #{object_identifier} is empty" if version.empty?

          version
        end

        # Close current version for an object
        # @param params [Hash] optional params (see dor-services-app)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [String] a message confirming successful closing
        def close(**params)
          resp = connection.post do |req|
            req.url close_version_path
            req.headers['Content-Type'] = 'application/json'
            req.body = params.to_json if params.any?
          end
          return resp.body if resp.success?

          raise_exception_based_on_response!(resp)
        end

        private

        attr_reader :object_identifier

        def object_path
          "#{api_version}/objects/#{object_identifier}"
        end

        def raise_exception_based_on_response!(response)
          raise (response.status == 404 ? NotFoundResponse : UnexpectedResponse),
                "#{response.reason_phrase}: #{response.status} (#{response.body})"
        end

        # Make request to server to open a new version
        # @param params [Hash] optional params (see dor-services-app)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raises [UnexpectedResponse] on an unsuccessful response from the server
        # @returns [String] the plain text from the server
        def open_new_version_response(**params)
          resp = connection.post do |req|
            req.url open_new_version_path
            req.headers['Content-Type'] = 'application/json'
            req.body = params.to_json if params.any?
          end
          return resp.body if resp.success?

          raise_exception_based_on_response!(resp)
        end

        def open_new_version_path
          "#{object_path}/versions"
        end

        def close_version_path
          "#{object_path}/versions/current/close"
        end
      end
    end
  end
end
