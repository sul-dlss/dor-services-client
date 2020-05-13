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

        # rubocop:disable Metrics/MethodLength
        def raise_exception_based_on_response!(response, object_identifier = nil)
          exception_class = case response.status
                            when 404
                              NotFoundResponse
                            when 401
                              UnauthorizedResponse
                            when 409
                              ConflictResponse
                            else
                              UnexpectedResponse
                            end
          raise exception_class,
                ResponseErrorFormatter.format(response: response, object_identifier: object_identifier)
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
