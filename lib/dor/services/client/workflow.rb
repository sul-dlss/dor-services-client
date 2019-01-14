# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about workflow
      class Workflow < VersionedService
        # @param object_id [String] the pid for the object
        def initialize(connection:, version:, object_id:)
          super(connection: connection, version: version)
          @object_id = object_id
        end

        # Begin a new workflow
        # @param wf_name [String] the name of the workflow
        # @raises [UnexpectedResponse] if the request is unsuccessful.
        # @return nil
        def create(wf_name:)
          resp = connection.post do |req|
            req.url "#{api_version}/objects/#{object_id}/apo_workflows/#{wf_name}"
          end
          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?
        end

        private

        attr_reader :object_id
      end
    end
  end
end
