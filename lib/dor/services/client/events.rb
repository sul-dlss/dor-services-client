# frozen_string_literal: true

require 'active_support/json' # required for serializing time as iso8601

module Dor
  module Services
    class Client
      # API calls that are about retrieving metadata
      class Events < VersionedService
        Event = Struct.new(:event_type, :data, keyword_init: true)

        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # @return [Array<Events>] The events for an object
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        def list
          resp = connection.get do |req|
            req.url "#{api_version}/objects/#{object_identifier}/events"
          end
          return response_to_models(resp) if resp.success?
          return if resp.status == 404

          raise UnexpectedResponse, ResponseErrorFormatter.format(response: resp, object_identifier: object_identifier)
        end

        private

        attr_reader :object_identifier

        def response_to_models(resp)
          JSON.parse(resp.body).map { |data| Event.new(event_type: data['event_type'], data: data['data']) }
        end
      end
    end
  end
end
