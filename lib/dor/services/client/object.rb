# frozen_string_literal: true

require 'dor/services/client/files'
require 'dor/services/client/release_tags'
require 'dor/services/client/sdr'
require 'dor/services/client/workflow'
require 'dor/services/client/workspace'

module Dor
  module Services
    class Client
      # API calls that are about a repository object
      class Object < VersionedService
        # @param object_id [String] the pid for the object
        def initialize(connection:, version:, object_id:)
          raise ArgumentError, "The `object_id` parameter must be an identifier string: #{object_id.inspect}" unless object_id.is_a?(String)

          super(connection: connection, version: version)
          @object_id = object_id
        end

        def sdr
          @sdr ||= SDR.new(connection: connection, version: api_version, object_id: object_id)
        end

        def files
          @files ||= Files.new(connection: connection, version: api_version, object_id: object_id)
        end

        def workflow
          @workflow ||= Workflow.new(connection: connection, version: api_version, object_id: object_id)
        end

        def workspace
          @workspace ||= Workspace.new(connection: connection, version: api_version, object_id: object_id)
        end

        def release_tags
          @release_tags ||= ReleaseTags.new(connection: connection, version: api_version, object_id: object_id)
        end

        # Publish a new object
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def publish
          resp = connection.post do |req|
            req.url "#{object_path}/publish"
          end
          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?

          true
        end

        # Notify the external Goobi system for a new object that was registered in DOR
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def notify_goobi
          resp = connection.post do |req|
            req.url "#{object_path}/notify_goobi"
          end
          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?

          true
        end

        # Get the current_version for a DOR object. This comes from Dor::VersionMetadataDS
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [String] the version identifier
        def current_version
          resp = connection.get do |req|
            req.url "#{object_path}/versions/current"
          end
          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?

          resp.body
        end

        # Open new version for an object
        # @param params [Hash] optional params (see dor-services-app)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @raise [MalformedResponse] when the response is not parseable.
        # @return [String] the current version
        def open_new_version(**params)
          version = open_new_version_response(**params)
          raise MalformedResponse, "Version of #{object_id} is empty" if version.empty?

          version
        end

        # Close current version for an object
        # @param params [Hash] optional params (see dor-services-app)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [String] a message confirming successful closing
        def close_version(**params)
          resp = connection.post do |req|
            req.url close_version_path
            req.headers['Content-Type'] = 'application/json'
            req.body = params.to_json if params.any?
          end
          return resp.body if resp.success?

          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body}) for #{object_id}"
        end

        private

        attr_reader :object_id

        def object_path
          "#{api_version}/objects/#{object_id}"
        end

        # Make request to server to open a new version
        # @param params [Hash] optional params (see dor-services-app)
        # @raises [UnexpectedResponse] on an unsuccessful response from the server
        # @returns [String] the plain text from the server
        def open_new_version_response(**params)
          resp = connection.post do |req|
            req.url open_new_version_path
            req.headers['Content-Type'] = 'application/json'
            req.body = params.to_json if params.any?
          end
          return resp.body if resp.success?

          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body}) for #{object_id}"
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
