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
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @param [String] workflow (nil) which workflow to callback to.
        # @param [String] lane_id for prioritization (default or low)
        # @return [String] the URL of the background job on dor-service-app
        def cleanup(workflow: nil, lane_id: nil)
          resp = connection.delete do |req|
            req.url with_query_params(workspace_path, workflow, lane_id)
          end
          return resp.headers['Location'] if resp.success?

          raise_exception_based_on_response!(resp, object_identifier)
        end

        # After an object has been copied to preservation the workspace can be
        # reset. This is called by the reset-workspace step of the accessionWF
        # @param [String] workflow (nil) which workflow to callback to.
        # @param [String] lane_id for prioritization (default or low)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return nil
        def reset(workflow: nil, lane_id: nil)
          resp = connection.post do |req|
            req.url with_query_params("#{workspace_path}/reset", workflow, lane_id)
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?
        end

        private

        def workspace_path
          "#{api_version}/objects/#{object_identifier}/workspace"
        end

        def query_params_for(workflow, lane_id)
          [].tap do |params|
            params << "workflow=#{workflow}" if workflow
            params << "lane-id=#{lane_id}" if lane_id
          end
        end

        def with_query_params(url, workflow, lane_id)
          query_params = query_params_for(workflow, lane_id)
          return url unless query_params.any?

          "#{url}?#{query_params.join('&')}"
        end

        attr_reader :object_identifier
      end
    end
  end
end
