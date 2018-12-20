# frozen_string_literal: true

module Dor
  module Services
    class Client
      # @abstract API calls to a versioned endpoint
      class VersionedService
        def initialize(connection:, version:)
          @connection = connection
          @version = version
        end

        private

        attr_reader :connection, :version
      end
    end
  end
end
