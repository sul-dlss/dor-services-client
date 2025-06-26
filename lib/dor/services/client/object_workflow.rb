# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls around workflow for an object.
      class ObjectWorkflow < VersionedService
        # @param object_identifier [String] the druid for the object
        # @param [String] workflow_name The name of the workflow
        def initialize(connection:, version:, object_identifier:, workflow_name:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
          @workflow_name = workflow_name
        end

        # @return [Workflow::Response::Workflow]
        def find
          resp = connection.get do |req|
            req.url "#{api_version}/objects/#{object_identifier}/workflows/#{workflow_name}"
            req.headers['Accept'] = 'application/xml'
          end
          raise_exception_based_on_response!(resp) unless resp.success?

          Dor::Services::Response::Workflow.new(xml: Nokogiri::XML(resp.body))
        end

        private

        attr_reader :object_identifier, :workflow_name
      end
    end
  end
end
