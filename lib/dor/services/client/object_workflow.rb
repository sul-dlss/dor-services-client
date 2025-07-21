# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls around workflow for an object.
      class ObjectWorkflow < VersionedService
        attr_reader :workflow_name

        # @param object_identifier [String] the druid for the object
        # @param [String] workflow_name The name of the workflow
        def initialize(connection:, version:, object_identifier:, workflow_name:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
          @workflow_name = workflow_name
        end

        # @return [Dor::Services::Client::Process]
        def process(process)
          raise ArgumentError, '`process` argument cannot be blank in call to `#process(process)`' if process.blank?

          # Return memoized object instance if process value is the same
          #
          # This allows the client to interact with multiple workflows for a given object
          return @process if @process&.process == process

          @process = Process.new(connection: connection, version: api_version, object_identifier: object_identifier,
                                 workflow_name: workflow_name, process: process, object_workflow_client: self)
        end

        # @return [Workflow::Response::Workflow]
        def find
          resp = connection.get do |req|
            req.url "#{api_version}/objects/#{object_identifier}/workflows/#{workflow_name}"
            req.headers['Accept'] = 'application/xml'
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          Dor::Services::Response::Workflow.new(xml: resp.body)
        end

        # Creates a workflow for a given object in the repository.  If this particular workflow for this objects exists,
        # it will replace the old workflow.
        # @param [Integer] version
        # @param [String] lane_id adds laneId attribute to all process elements in the wf_xml workflow xml.  Defaults to a value of 'default'
        # @param [Hash] context optional context to be included in the workflow (same for all processes for a given druid/version pair)
        def create(version:, lane_id: 'default', context: nil) # rubocop:disable Metrics/AbcSize
          resp = connection.post do |req|
            req.url "#{api_version}/objects/#{object_identifier}/workflows/#{workflow_name}"
            req.params['version'] = version
            req.params['lane-id'] = lane_id
            req.headers['Content-Type'] = 'application/json'
            req.body = { context: context }.to_json if context
          end

          raise_exception_based_on_response!(resp) unless resp.success?
        end

        # Skips all steps in a workflow.
        # @param note [String] a note to be added to the skipped steps
        def skip_all(note:)
          resp = connection.post do |req|
            req.url "#{api_version}/objects/#{object_identifier}/workflows/#{workflow_name}/skip_all"
            req.params['note'] = note
          end

          raise_exception_based_on_response!(resp) unless resp.success?
        end

        private

        attr_reader :object_identifier
      end
    end
  end
end
