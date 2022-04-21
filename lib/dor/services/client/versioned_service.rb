# frozen_string_literal: true

module Dor
  module Services
    class Client
      # @abstract API calls to a versioned endpoint
      class VersionedService
        EXCEPTION_CLASS = {
          400 => BadRequestError,
          401 => UnauthorizedResponse,
          404 => NotFoundResponse,
          409 => ConflictResponse,
          412 => PreconditionFailedResponse
        }.freeze

        JSON_API_MIME_TYPE = 'application/vnd.api+json'

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
          data = if response.headers.fetch('content-type', '').start_with?(JSON_API_MIME_TYPE)
                   JSON.parse(response.body)
                 else
                   {}
                 end
          exception_class = EXCEPTION_CLASS.fetch(response.status, UnexpectedResponse)
          raise exception_class.new(response: response,
                                    object_identifier: object_identifier,
                                    errors: data.fetch('errors', []))
        end

        def build_cocina_from_response(response)
          cocina_object = Cocina::Models.build(JSON.parse(response.body))
          Cocina::Models.with_metadata(cocina_object, response.headers['ETag'], created: date_from_header(response, 'X-Created-At'),
                                                                                modified: date_from_header(response, 'Last-Modified'))
        end

        def build_json_from_cocina(cocina_object)
          Cocina::Models.without_metadata(cocina_object).to_json
        end

        def date_from_header(response, key)
          response.headers[key]&.to_datetime
        end
      end
    end
  end
end
