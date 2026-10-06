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

        # @param type [String] a type for the event, e.g., version_open, publishing_complete. Must be a known event type (see EventTypes#list).
        # @param data [Hash] an unstructured hash of event data
        # @return [Boolean] true if successful
        # @raise [BadRequestError] when the event is invalid, e.g., the event type is unknown
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
        # @param from [Time,Date,String,NilClass] only events created at or after this time (inclusive), or nil for no lower bound.
        #   A String must be an ISO 8601 date or date-time; UTC if no offset is given.
        # @param to [Time,Date,String,NilClass] only events created before this time (exclusive), or nil for no upper bound.
        #   A String must be an ISO 8601 date or date-time; UTC if no offset is given.
        # @return [Array<Event>,NilClass] The events for an object or nil if 404
        # @raise [BadRequestError] when from or to is invalid
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        def list(event_types: nil, from: nil, to: nil)
          resp = connection.get("#{api_version}/objects/#{object_identifier}/events",
                                { event_types: event_types, from: iso8601(from), to: iso8601(to) }.compact)
          return response_to_models(resp) if resp.success?
          return if resp.status == 404

          raise_exception_based_on_response!(resp, object_identifier)
        end

        private

        attr_reader :object_identifier

        def iso8601(value)
          value.respond_to?(:iso8601) ? value.iso8601 : value
        end

        def response_to_models(resp)
          JSON.parse(resp.body).map { |data| Event.new(event_type: data['event_type'], data: data['data'], timestamp: data['created_at']) }
        end
      end
    end
  end
end
