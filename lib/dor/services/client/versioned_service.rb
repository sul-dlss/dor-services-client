# frozen_string_literal: true

module Dor
  module Services
    class Client
      # @abstract API calls to a versioned endpoint
      class VersionedService
        def initialize(connection:, version:)
          @connection = connection
          @api_version = version
        end

        private

        attr_reader :connection, :api_version
      end
    end
  end
end
