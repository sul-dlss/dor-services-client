# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about retrieving metadata
      class Events < VersionedService
        Event = Struct.new(:event_type, :data, :timestamp, keyword_init: true)

        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # @param type [String] a type for the event, e.g., publish, shelve
        # @param data [Hash] an unstructured hash of event data
        # @return [Boolean] true if successful
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        def create(type:, data:)
          resp = connection.post do |req|
            req.url "#{api_version}/objects/#{object_identifier}/events"
            req.headers['Content-Type'] = 'application/json'
            req.body = { event_type: type, data: data }.to_json
          end

          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          true
        end

        # @param event_types [Array<String>,NilClass] an array of event types to filter by, or nil for all
        # @return [Array<Event>,NilClass] The events for an object or nil if 404
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        def list(event_types: nil)
          resp = connection.get("#{api_version}/objects/#{object_identifier}/events",
                                { event_types: event_types }.compact)
          return response_to_models(resp) if resp.success?
          return if resp.status == 404

          raise_exception_based_on_response!(resp, object_identifier)
        end

        private

        attr_reader :object_identifier

        def response_to_models(resp)
          JSON.parse(resp.body).map { |data| Event.new(event_type: data['event_type'], data: data['data'], timestamp: data['created_at']) }
        end
      end
    end
  end
end
