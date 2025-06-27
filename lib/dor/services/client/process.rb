# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls around workflow process for an object.
      class Process < VersionedService
        # @param object_identifier [String] the druid for the object
        # @param [String] workflow_name The name of the workflow
        # @param [String] process The name of the workflow step
        def initialize(connection:, version:, object_identifier:, workflow_name:, process:, object_workflow_client:) # rubocop:disable Metrics/ParameterLists
          super(connection: connection, version: version)
          @object_identifier = object_identifier
          @workflow_name = workflow_name
          @process = process
          @object_workflow_client = object_workflow_client
        end

        # Retrieves the process status of the given workflow for the given object identifier
        # @return [String,nil] status
        def status
          doc = object_workflow_client.find.xml

          processes = doc.root.xpath("//process[@name='#{process}']")
          process = processes.max { |a, b| a.attr('version').to_i <=> b.attr('version').to_i }
          process&.attr('status')
        end

        # Updates the status of one step in a workflow.
        # @param [String] status The status of the process.
        # @param [Float] elapsed The number of seconds it took to complete this step. Can have a decimal.  Is set to 0 if not passed in.
        # @param [String] lifecycle Bookeeping label for this particular workflow step.  Examples are: 'registered', 'shelved'
        # @param [String] note Any kind of string annotation that you want to attach to the workflow
        # @param [String] current_status Setting this string tells the workflow service to compare the current status to this value.
        # @raise [Dor::Services::Client::ConflictResponse] if the current status does not match the value passed in current_status.
        def update(status:, elapsed: 0, lifecycle: nil, note: nil, current_status: nil)
          perform_update(status: status, elapsed: elapsed, lifecycle: lifecycle, note: note, current_status: current_status)
        end

        # Updates the status of one step in a workflow to error.
        # @param [String] error_msg The error message.  Ideally, this is a brief message describing the error
        # @param [String] error_text A slot to hold more information about the error, like a full stacktrace
        def update_error(error_msg:, error_text: nil)
          perform_update(status: 'error', error_msg: error_msg, error_text: error_text)
        end

        private

        attr_reader :object_identifier, :workflow_name, :process, :object_workflow_client

        def perform_update(**payload)
          resp = connection.put do |req|
            req.url "#{api_version}/objects/#{object_identifier}/workflows/#{workflow_name}/processes/#{process}"
            req.headers['Content-Type'] = 'application/json'
            req.body = payload.compact.to_json
          end

          raise_exception_based_on_response!(resp) unless resp.success?
        end
      end
    end
  end
end
