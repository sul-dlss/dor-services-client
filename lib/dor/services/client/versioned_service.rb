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

        # Common interface for handling asynchronous results
        def async_result(url:)
          AsyncResult.new(url: url)
        end

        private

        attr_reader :connection, :api_version

        def raise_exception_based_on_response!(response, object_identifier = nil)
          raise (response.status == 404 ? NotFoundResponse : UnexpectedResponse),
                ResponseErrorFormatter.format(response: response, object_identifier: object_identifier)
        end
      end
    end
  end
end
