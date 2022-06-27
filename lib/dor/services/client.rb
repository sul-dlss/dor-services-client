# frozen_string_literal: true

require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/object/blank'
require 'active_support/json'
require 'active_support/core_ext/object/json'
require 'bunny'
require 'cocina/models'
require 'faraday'
require 'faraday/retry'
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

      # Base class for Dor::Services::Client exceptions
      class Error < StandardError; end

      # Error that is raised when the ultimate remote server returns a 404 Not Found for the id in our request (e.g. for druid, barcode, catkey)
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
        # rubocop:disable Lint/MissingSuper
        def initialize(response:, object_identifier: nil, errors: nil)
          @response = response
          @object_identifier = object_identifier
          @errors = errors
        end
        # rubocop:enable Lint/MissingSuper

        attr_accessor :errors

        def to_s
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

      # @param object_identifier [String] the pid for the object
      # @raise [ArgumentError] when `object_identifier` is `nil`
      # @return [Dor::Services::Client::Object] an instance of the `Client::Object` class
      def object(object_identifier)
        raise ArgumentError, '`object_identifier` argument cannot be `nil` in call to `#object(object_identifier)' if object_identifier.nil?

        # Return memoized object instance if object identifier value is the same
        # This allows us to test the client more easily in downstream codebases,
        # opening up stubbing without requiring `any_instance_of`
        return @object if @object&.object_identifier == object_identifier

        @object = Object.new(connection: connection, version: DEFAULT_VERSION, object_identifier: object_identifier, channel: channel)
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

        def configure_rabbit(hostname:, vhost:, username:, password:)
          instance.hostname = hostname
          instance.vhost = vhost
          instance.username = username
          instance.password = password

          # Force channel to be re-established when `.configure_rabbit` is called
          instance.channel = nil

          self
        end

        delegate :background_job_results, :marcxml, :objects, :object,
                 :virtual_objects, :administrative_tags, to: :instance
      end

      attr_writer :url, :token, :connection, :enable_get_retries, :hostname, :vhost, :username, :password, :channel

      private

      attr_reader :token, :enable_get_retries, :url, :hostname, :vhost, :username, :password

      def connection
        # Note that since this is a singleton, there will be only one connection created.
        @connection ||= HttpConnectionFactory.new(url: url, token: token, enable_get_retries: enable_get_retries)
      end

      def channel
        @channel ||= RabbitChannelFactory.new(hostname: hostname, vhost: vhost, username: username, password: password)
      end
    end
  end
end
