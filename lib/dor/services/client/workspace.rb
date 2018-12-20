# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about the DOR workspace
      class Workspace < VersionedService
        # Initializes a new workspace
        # @param object [String] the pid for the object
        # @param source [String] the path to the object
        # @raises [UnexpectedResponse] if the request is unsuccessful.
        # @return nil
        def create(object:, source:)
          resp = connection.post do |req|
            req.url "#{api_version}/objects/#{object}/initialize_workspace"
            req.params['source'] = source
          end
          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?
        end
      end
    end
  end
end
