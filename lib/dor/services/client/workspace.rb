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
        # @raises [UnexpectedResponse] if the request is unsuccessful.
        # @return nil
        def create(source:)
          resp = connection.post do |req|
            req.url workspace_path
            req.params['source'] = source
          end
          raise UnexpectedResponse, ResponseErrorFormatter.format(response: resp) unless resp.success?
        end

        # Cleans up a workspace
        # @raises [UnexpectedResponse] if the request is unsuccessful.
        # @return nil
        def cleanup
          resp = connection.delete do |req|
            req.url workspace_path
          end
          raise UnexpectedResponse, ResponseErrorFormatter.format(response: resp) unless resp.success?
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
