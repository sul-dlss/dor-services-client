# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about the DOR workspace
      class Workspace < VersionedService
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Initializes a new workspace
        # @param source [String] the path to the object
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return nil
        def create(source:)
          resp = connection.post do |req|
            req.url workspace_path
            req.params['source'] = source
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?
        end

        # Cleans up a workspace
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return nil
        def cleanup
          resp = connection.delete do |req|
            req.url workspace_path
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?
        end

        # After an object has been copied to preservation the workspace can be
        # reset. This is called by the reset-workspace step of the accessionWF
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return nil
        def reset
          resp = connection.post do |req|
            req.url "#{workspace_path}/reset"
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?
        end

        private

        def workspace_path
          "#{api_version}/objects/#{object_identifier}/workspace"
        end

        attr_reader :object_identifier
      end
    end
  end
end
