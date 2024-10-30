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
        # @param source [String] the path to the object (optional)
        # @param content [Boolean] determines if the content directory should be created (defaults to false)
        # @param metadata [Boolean] determines if the metadata directory should be created (defaults to false)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return [String] the path to the directory created
        # rubocop:disable Metrics/AbcSize
        def create(source: nil, content: false, metadata: false)
          resp = connection.post do |req|
            req.url workspace_path
            req.params['source'] = source if source
            req.params['content'] = content
            req.params['metadata'] = metadata
          end
          return JSON.parse(resp.body)['path'] if resp.success?

          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?
        end
        # rubocop:enable Metrics/AbcSize

        private

        def workspace_path
          "#{api_version}/objects/#{object_identifier}/workspace"
        end

        attr_reader :object_identifier
      end
    end
  end
end
