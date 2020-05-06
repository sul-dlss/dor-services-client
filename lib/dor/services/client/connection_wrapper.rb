# frozen_string_literal: true

module Dor
  module Services
    class Client
      # Wraps connections to allow GET requests to be retriable.
      class ConnectionWrapper
        delegate :get, to: :get_connection
        delegate :post, :delete, :put, :patch, to: :connection

        def initialize(connection:, get_connection:)
          @connection = connection
          @get_connection = get_connection
        end

        private

        attr_reader :connection, :get_connection
      end
    end
  end
end
