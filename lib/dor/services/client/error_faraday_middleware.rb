# frozen_string_literal: true

module Dor
  module Services
    class Client
      # This wraps any faraday connection errors with dor-services-client errors
      class ErrorFaradayMiddleware < Faraday::Middleware
        def call(env)
          @app.call(env)
        rescue Faraday::ConnectionFailed => e
          raise ConnectionFailed, "unable to reach dor-services-app: #{e}", e.backtrace
        end
      end
    end
  end
end
