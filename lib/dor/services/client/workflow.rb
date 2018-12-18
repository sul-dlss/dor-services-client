# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about workflow
      class Workflow
        def initialize(connection:)
          @connection = connection
        end

        attr_reader :connection

        # Begin a new workflow
        # @param object [String] the pid for the object
        # @param wf_name [String] the name of the workflow
        # @raises [Error] if the request is unsuccessful.
        # @return nil
        def create(object:, wf_name:)
          resp = connection.post do |req|
            req.url "v1/objects/#{object}/apo_workflows/#{wf_name}"
          end
          raise Error, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?
        end
      end
    end
  end
end
