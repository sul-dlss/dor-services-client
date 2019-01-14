# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about the DOR workspace
      class Workspace < VersionedService
        # @param object_id [String] the pid for the object
        def initialize(connection:, version:, object_id:)
          super(connection: connection, version: version)
          @object_id = object_id
        end

        # Initializes a new workspace
        # @param source [String] the path to the object
        # @raises [UnexpectedResponse] if the request is unsuccessful.
        # @return nil
        def create(source:)
          resp = connection.post do |req|
            req.url "#{api_version}/objects/#{object_id}/initialize_workspace"
            req.params['source'] = source
          end
          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?
        end

        private

        attr_reader :object_id
      end
    end
  end
end
