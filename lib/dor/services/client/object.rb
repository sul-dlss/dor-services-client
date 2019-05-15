# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about a repository object
      class Object < VersionedService
        attr_reader :object_identifier

        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          raise ArgumentError, "The `object_identifier` parameter must be an identifier string: #{object_identifier.inspect}" unless object_identifier.is_a?(String)

          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        def sdr
          @sdr ||= SDR.new(connection: connection, version: api_version, object_identifier: object_identifier)
        end

        def metadata
          @metadata ||= Metadata.new(connection: connection, version: api_version, object_identifier: object_identifier)
        end

        def files
          @files ||= Files.new(connection: connection, version: api_version, object_identifier: object_identifier)
        end

        def workflow
          @workflow ||= Workflow.new(connection: connection, version: api_version, object_identifier: object_identifier)
        end

        def workspace
          @workspace ||= Workspace.new(connection: connection, version: api_version, object_identifier: object_identifier)
        end

        def release_tags
          @release_tags ||= ReleaseTags.new(connection: connection, version: api_version, object_identifier: object_identifier)
        end

        # Publish a new object
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def publish
          resp = connection.post do |req|
            req.url "#{object_path}/publish"
          end
          return true if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Update the marc record for the give object
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def update_marc_record
          resp = connection.post do |req|
            req.url "#{object_path}/update_marc_record"
          end
          return true if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Pull in metadata from Symphony and update descMetadata
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def refresh_metadata
          resp = connection.post do |req|
            req.url "#{object_path}/refresh_metadata"
          end
          return true if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Notify the external Goobi system for a new object that was registered in DOR
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def notify_goobi
          resp = connection.post do |req|
            req.url "#{object_path}/notify_goobi"
          end
          return true if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Get the current_version for a DOR object. This comes from Dor::VersionMetadataDS
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [String] the version identifier
        def current_version
          resp = connection.get do |req|
            req.url "#{object_path}/versions/current"
          end
          return resp.body if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Open new version for an object
        # @param params [Hash] optional params (see dor-services-app)
        # @raise [MalformedResponse] when the response is not parseable.
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [String] the current version
        def open_new_version(**params)
          version = open_new_version_response(**params)
          raise MalformedResponse, "Version of #{object_identifier} is empty" if version.empty?

          version
        end

        # Close current version for an object
        # @param params [Hash] optional params (see dor-services-app)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [String] a message confirming successful closing
        def close_version(**params)
          resp = connection.post do |req|
            req.url close_version_path
            req.headers['Content-Type'] = 'application/json'
            req.body = params.to_json if params.any?
          end
          return resp.body if resp.success?

          raise_exception_based_on_response!(resp)
        end

        private

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
