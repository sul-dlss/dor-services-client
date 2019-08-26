# frozen_string_literal: true

module Dor
  module Services
    class Client
      # Format HTTP response-related errors
      class ResponseErrorFormatter
        DEFAULT_BODY = 'Response from dor-services-app did not contain a body. \
                        Check honeybadger for dor-services-app for backtraces, \
                        and look into adding a `rescue_from` in dor-services-app \
                        to provide more details to the client in the future'

        def self.format(response:)
          new(response: response).format
        end

        attr_reader :reason_phrase, :status, :body

        def initialize(response:)
          @reason_phrase = response.reason_phrase
          @status = response.status
          @body = response.body.present? ? response.body : DEFAULT_BODY
        end

        def format
          "#{reason_phrase}: #{status} (#{body})"
        end
      end
    end
  end
end
