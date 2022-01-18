# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that move data around.
      class Transfer < VersionedService
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Publish an object (send to PURL)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @param [String] workflow (nil) which workflow to callback to.
        # @param [String] lane_id for prioritization (default or low)
        # @return [String] the URL of the background job on dor-service-app
        def publish(workflow: nil, lane_id: nil)
          query_params = [].tap do |params|
            params << "workflow=#{workflow}" if workflow
            params << "lane-id=#{lane_id}" if lane_id
          end
          query_string = query_params.any? ? "?#{query_params.join('&')}" : ''
          publish_path = "#{object_path}/publish#{query_string}"
          resp = connection.post do |req|
            req.url publish_path
          end
          return resp.headers['Location'] if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Unpublish an object (yank from to PURL)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [String] the URL of the background job on dor-service-app
        def unpublish
          resp = connection.post do |req|
            req.url "#{object_path}/unpublish"
          end
          return resp.headers['Location'] if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Preserve an object (send to SDR)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @param [String] lane_id for prioritization (default or low)
        # @return [String] URL from Location response header if no errors
        def preserve(lane_id: nil)
          query_string = lane_id ? "?lane-id=#{lane_id}" : ''
          resp = connection.post do |req|
            req.url "#{object_path}/preserve#{query_string}"
          end
          return resp.headers['Location'] if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Shelve an object (send to Stacks)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @param [String] lane_id for prioritization (default or low)
        # @return [boolean] true on success
        def shelve(lane_id: nil)
          query_string = lane_id ? "?lane-id=#{lane_id}" : ''
          resp = connection.post do |req|
            req.url "#{object_path}/shelve#{query_string}"
          end
          return resp.headers['Location'] if resp.success?

          raise_exception_based_on_response!(resp)
        end

        private

        def object_path
          "#{api_version}/objects/#{object_identifier}"
        end

        attr_reader :object_identifier
      end
    end
  end
end
