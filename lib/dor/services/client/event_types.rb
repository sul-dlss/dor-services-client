# frozen_string_literal: true

require 'json'

module Dor
  module Services
    class Client
      # API calls around event types from dor-services-app
      class EventTypes < VersionedService
        # List the valid event types
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        # @return [Array<String>] the valid event types, sorted
        def list
          resp = connection.get do |req|
            req.url "#{api_version}/event_types"
            req.headers['Accept'] = 'application/json'
          end

          return JSON.parse(resp.body) if resp.success?

          raise_exception_based_on_response!(resp)
        end
      end
    end
  end
end
