# frozen_string_literal: true

module Dor
  module Services
    class Client
      # Factory for creating HTTP connections.
      # Note that that connection is lazily created.
      class HttpConnectionFactory
        TOKEN_HEADER = 'Authorization'

        def initialize(url:, token:, enable_get_retries:)
          @url = url
          @token = token
          @enable_get_retries = enable_get_retries
        end

        delegate :post, :patch, :get, :put, :delete, to: :connection

        private

        attr_reader :token, :enable_get_retries

        def url
          @url || raise(Error, 'url has not yet been configured')
        end

        def connection
          @connection ||= ConnectionWrapper.new(connection: build_connection, get_connection: build_connection(with_retries: enable_get_retries))
        end

        def build_connection(with_retries: false)
          Faraday.new(url) do |builder|
            builder.use ErrorFaradayMiddleware
            builder.use Faraday::Request::UrlEncoded

            # @note when token & token_header are nil, this line is required else
            #   the Faraday instance will be passed an empty block, which
            #   causes the adapter not to be set. Thus, everything breaks.
            builder.adapter Faraday.default_adapter
            builder.headers[:user_agent] = user_agent
            builder.headers[TOKEN_HEADER] = "Bearer #{token}"
            builder.request :retry, max: 4, interval: 1, backoff_factor: 2 if with_retries
          end
        end

        def user_agent
          "dor-services-client #{Dor::Services::Client::VERSION}"
        end
      end
    end
  end
end
