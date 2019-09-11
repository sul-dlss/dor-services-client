# frozen_string_literal: true

module Dor
  module Services
    class Client
      # Format HTTP response-related errors
      class ResponseErrorFormatter
        DEFAULT_BODY = "Response from dor-services-app did not contain a body. \
                        Check honeybadger for dor-services-app for backtraces, \
                        and look into adding a `rescue_from` in dor-services-app \
                        to provide more details to the client in the future"

        def self.format(response:, object_identifier: nil)
          new(response: response, object_identifier: object_identifier).format
        end

        attr_reader :reason_phrase, :status, :body, :object_identifier

        def initialize(response:, object_identifier: nil)
          @reason_phrase = response.reason_phrase
          @status = response.status
          @body = response.body.present? ? response.body : DEFAULT_BODY
          @object_identifier = object_identifier
        end

        def format
          return "#{reason_phrase}: #{status} (#{body})" if object_identifier.nil?

          "#{reason_phrase}: #{status} (#{body}) for #{object_identifier}"
        end
      end
    end
  end
end
