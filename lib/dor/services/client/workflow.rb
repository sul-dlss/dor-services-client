# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about workflow
      class Workflow < VersionedService
        # Begin a new workflow
        # @param object [String] the pid for the object
        # @param wf_name [String] the name of the workflow
        # @raises [UnexpectedResponse] if the request is unsuccessful.
        # @return nil
        def create(object:, wf_name:)
          resp = connection.post do |req|
            req.url "#{version}/objects/#{object}/apo_workflows/#{wf_name}"
          end
          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?
        end
      end
    end
  end
end
