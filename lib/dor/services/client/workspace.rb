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
        # @param [String] lane_id for prioritization (default or low)
        # @return nil
        def cleanup(lane_id: nil)
          resp = connection.delete do |req|
            req.url workspace_path(lane_id: lane_id)
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

        def workspace_path(lane_id: nil)
          query_string = lane_id ? "?lane-id=#{lane_id}" : ''
          "#{api_version}/objects/#{object_identifier}/workspace#{query_string}"
        end

        attr_reader :object_identifier
      end
    end
  end
end
