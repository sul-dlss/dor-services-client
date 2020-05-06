# frozen_string_literal: true

require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'active_support/json'
require 'active_support/core_ext/object/json'
require 'cocina/models'
require 'faraday'
require 'singleton'
require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.inflector = Zeitwerk::GemInflector.new(__FILE__)
loader.push_dir(File.absolute_path("#{__FILE__}/../../.."))
loader.setup

module Dor
  module Services
    class Client
      include Singleton

      DEFAULT_VERSION = 'v1'
      TOKEN_HEADER = 'Authorization'

      # Base class for Dor::Services::Client exceptions
      class Error < StandardError; end

      # Error that is raised when the remote server returns a 404 Not Found
      class NotFoundResponse < Error; end

      # Error that is raised when the remote server returns some unexpected response
      # this could be any 4xx or 5xx status
      class UnexpectedResponse < Error; end

      # Error that is raised when the remote server returns a 401 Unauthorized
      class UnauthorizedResponse < UnexpectedResponse; end

      # Error that is raised when the remote server returns some unparsable response
      class MalformedResponse < Error; end

      # Error that wraps Faraday connection exceptions
      class ConnectionFailed < Error; end

      # @param object_identifier [String] the pid for the object
      # @raise [ArgumentError] when `object_identifier` is `nil`
      # @return [Dor::Services::Client::Object] an instance of the `Client::Object` class
      def object(object_identifier)
        raise ArgumentError, '`object_identifier` argument cannot be `nil` in call to `#object(object_identifier)' if object_identifier.nil?

        # Return memoized object instance if object identifier value is the same
        # This allows us to test the client more easily in downstream codebases,
        # opening up stubbing without requiring `any_instance_of`
        return @object if @object&.object_identifier == object_identifier

        @object = Object.new(connection: connection, version: DEFAULT_VERSION, object_identifier: object_identifier)
      end

      # @return [Dor::Services::Client::Objects] an instance of the `Client::Objects` class
      def objects
        @objects ||= Objects.new(connection: connection, version: DEFAULT_VERSION)
      end

      # @return [Dor::Services::Client::VirtualObjects] an instance of the `Client::VirtualObjects` class
      def virtual_objects
        @virtual_objects ||= VirtualObjects.new(connection: connection, version: DEFAULT_VERSION)
      end

      # @return [Dor::Services::Client::BackgroundJobResults] an instance of the `Client::BackgroundJobResults` class
      def background_job_results
        @background_job_results ||= BackgroundJobResults.new(connection: connection, version: DEFAULT_VERSION)
      end

      # @return [Dor::Services::Client::Marcxml] an instance of the `Client::Marcxml` class
      def marcxml
        @marcxml ||= Marcxml.new(connection: connection, version: DEFAULT_VERSION)
      end

      class << self
        # @param [String] url the base url of the endpoint the client should connect to (required)
        # @param [String] token a bearer token for HTTP authentication (required)
        # @param [Boolean] enable_get_retries retries get requests on errors
        def configure(url:, token:, enable_get_retries: false)
          instance.url = url
          instance.token = token
          instance.enable_get_retries = enable_get_retries

          # Force connection to be re-established when `.configure` is called
          instance.connection = nil

          self
        end

        delegate :background_job_results, :marcxml, :objects, :object, :virtual_objects, to: :instance
      end

      attr_writer :url, :token, :connection, :enable_get_retries

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
          #       the Faraday instance will be passed an empty block, which
          #       causes the adapter not to be set. Thus, everything breaks.
          builder.adapter Faraday.default_adapter
          builder.headers[:user_agent] = user_agent
          builder.headers[TOKEN_HEADER] = "Bearer #{token}"
          if with_retries
            builder.request :retry, max: 4, interval: 1,
                                    backoff_factor: 2, exceptions: ['Faraday::Error', 'Timeout::Error']
          end
        end
      end

      def user_agent
        "dor-services-client #{Dor::Services::Client::VERSION}"
      end
    end
  end
end
