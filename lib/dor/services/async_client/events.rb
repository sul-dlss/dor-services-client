# frozen_string_literal: true

require 'active_support/json' # required for serializing time as iso8601

module Dor
  module Services
    class AsyncClient
      # API calls that are about events
      class Events
        # @param object_identifier [String] the pid for the object
        def initialize(channel:, object_identifier:)
          @channel = channel
          @object_identifier = object_identifier
        end

        # @param type [String] a type for the event, e.g., publish, shelve
        # @param data [Hash] an unstructured hash of event data
        # @return [Boolean] true if successful
        def create(type:, data:)
          message = { druid: object_identififer, event_type: type, data: data }
          exchange.publish(message.to_json, routing_key: type)
          true
        end

        private

        attr_reader :channel, :object_identifier

        def exchange
          channel.topic('sdr.objects.event')
        end
      end
    end
  end
end
