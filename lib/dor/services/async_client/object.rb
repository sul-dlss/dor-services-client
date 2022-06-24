# frozen_string_literal: true

module Dor
  module Services
    class AsyncClient
      # API calls that are about a repository object
      class Object
        attr_reader :object_identifier

        # @param object_identifier [String] the pid for the object
        def initialize(channel:, object_identifier:)
          raise ArgumentError, "The `object_identifier` parameter must be an identifier string: #{object_identifier.inspect}" unless object_identifier.is_a?(String)

          @channel = channel
          @object_identifier = object_identifier
        end

        def events
          @events ||= Events.new(channel: channel, object_identifier: object_identifier)
        end

        private

        attr_reader :channel
      end
    end
  end
end
