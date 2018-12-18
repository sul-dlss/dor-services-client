# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about the DOR workspace
      class Workspace
        def initialize(connection:)
          @connection = connection
        end

        attr_reader :connection

        # Initializes a new workspace
        # @param object [String] the pid for the object
        # @param source [String] the path to the object
        # @raises [Error] if the request is unsuccessful.
        # @return nil
        def create(object:, source:)
          resp = connection.post do |req|
            req.url "v1/objects/#{object}/initialize_workspace"
            req.params['source'] = source
          end
          raise Error, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?
        end
      end
    end
  end
end
