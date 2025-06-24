# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/json'
require 'active_support/core_ext/object/to_query'
require 'active_support/json'
require 'cocina/models'
require 'faraday'
require 'faraday/retry'
require 'nokogiri'
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

      # Error that is raised when the ultimate remote server returns a 404 Not Found for the id in our request (e.g. druid, barcode, catkey, folio_instance_hrid)
      class NotFoundResponse < Error; end

      # Error that is raised when the remote server returns some unparsable response
      class MalformedResponse < Error; end

      # Error that wraps Faraday connection exceptions
      class ConnectionFailed < Error; end

      # Error that is raised when the remote server returns some unexpected response
      # this could be any 4xx or 5xx status (except the ones that are direct children of the Error class above)
      class UnexpectedResponse < Error
        # @param [Faraday::Response] response
        # @param [String] object_identifier (nil)
        # @param [Hash<String,Object>] errors (nil) the JSON-API errors object
        # @param [Hash<String,Object>] graphql_errors (nil) the GraphQL errors object
        # rubocop:disable Lint/MissingSuper
        def initialize(response:, object_identifier: nil, errors: nil, graphql_errors: nil)
          @response = response
          @object_identifier = object_identifier
          @errors = errors
          @graphql_errors = graphql_errors
        end
        # rubocop:enable Lint/MissingSuper

        attr_accessor :errors, :graphql_errors

        def to_s
          # For GraphQL errors, see https://graphql-ruby.org/errors/execution_errors
          return graphql_errors.map { |e| e['message'] }.join(', ') if graphql_errors.present?
          return errors.map { |e| "#{e['title']} (#{e['detail']})" }.join(', ') if errors.present?

          ResponseErrorFormatter.format(response: @response, object_identifier: @object_identifier)
        end
      end

      # Error that is raised when the remote server returns a 401 Unauthorized
      class UnauthorizedResponse < UnexpectedResponse; end

      # Error that is raised when the remote server returns a 409 Conflict
      class ConflictResponse < UnexpectedResponse; end

      # Error that is raised when the remote server returns a 412 Precondition Failed.
      # This occurs when you sent an etag with If-Match, but the etag didn't match the latest version
      class PreconditionFailedResponse < UnexpectedResponse; end

      # Error that is raised when the remote server returns a 400 Bad Request; apps should not retry the request
      class BadRequestError < UnexpectedResponse; end

      module Types
        include Dry.Types()
      end

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

      # @return [Dor::Services::Client::AdministrativeTagSearch] an instance of the `Client::AdministrativeTagSearch` class
      def administrative_tags
        @administrative_tags ||= AdministrativeTagSearch.new(connection: connection, version: DEFAULT_VERSION)
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

      # @return [Dor::Services::Client::Workflows] an instance of the `Client::Workflows` class
      def workflows
        @workflows ||= Workflows.new(connection: connection, version: DEFAULT_VERSION)
      end

      class << self
        # @param [String] url the base url of the endpoint the client should connect to (required)
        # @param [String] token a bearer token for HTTP authentication (required)
        # @param [Boolean] enable_get_retries retries get requests on errors
        # @param [Logger,nil] logger for logging retry attempts
        def configure(url:, token:, enable_get_retries: true, logger: nil)
          instance.url = url
          instance.token = token
          instance.enable_get_retries = enable_get_retries
          instance.logger = logger

          # Force connection to be re-established when `.configure` is called
          instance.connection = nil

          self
        end

        delegate :background_job_results, :objects, :object, :virtual_objects, :administrative_tags, :workflows, to: :instance
      end

      attr_writer :url, :token, :connection, :enable_get_retries, :logger

      private

      attr_reader :token, :enable_get_retries, :logger

      def url
        @url || raise(Error, 'url has not yet been configured')
      end

      def connection
        @connection ||= build_connection(with_retries: enable_get_retries, logger: logger)
      end

      def build_connection(with_retries: false, logger: nil)
        Faraday.new(url) do |builder|
          builder.use ErrorFaradayMiddleware
          builder.use Faraday::Request::UrlEncoded

          # @note when token & token_header are nil, this line is required else
          #   the Faraday instance will be passed an empty block, which
          #   causes the adapter not to be set. Thus, everything breaks.
          builder.adapter Faraday.default_adapter
          # 5 minutes read timeout for very large cocina (eg. many files) object create/update (default if none set is 60 seconds)
          builder.options[:timeout] = 300
          builder.headers[:user_agent] = user_agent
          builder.headers[TOKEN_HEADER] = "Bearer #{token}"
          builder.request :retry, retry_options(logger) if with_retries
        end
      end

      def retry_options(logger) # rubocop:disable Metrics/MethodLength
        {
          max: 4,
          interval: 1,
          backoff_factor: 2,
          exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ConnectionFailed],
          methods: %i[get],
          retry_statuses: [503],
          # rubocop:disable Lint/UnusedBlockArgument
          retry_block: lambda { |env:, options:, retry_count:, exception:, will_retry_in:|
                         logger&.info("Retry #{retry_count + 1} for #{env.url} due to #{exception.class} (#{exception.message})")
                       }
          # rubocop:enable Lint/UnusedBlockArgument
        }
      end

      def user_agent
        "dor-services-client #{Dor::Services::Client::VERSION}"
      end
    end
  end
end
