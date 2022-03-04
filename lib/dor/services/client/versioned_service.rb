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
                            when 400
                              BadRequestError
                            when 401
                              UnauthorizedResponse
                            when 404
                              NotFoundResponse
                            when 409
                              ConflictResponse
                            when 412
                              PreconditionFailedResponse
                            else
                              UnexpectedResponse
                            end
          raise exception_class,
                ResponseErrorFormatter.format(response: response, object_identifier: object_identifier)
        end
        # rubocop:enable Metrics/MethodLength

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
