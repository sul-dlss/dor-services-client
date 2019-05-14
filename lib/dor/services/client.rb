# frozen_string_literal: true

require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/module/delegation'
require 'faraday'
require 'singleton'
require 'zeitwerk'

class DorServicesClientInflector < Zeitwerk::Inflector
  def camelize(basename, _abspath)
    case basename
    when 'sdr'
      'SDR'
    else
      super
    end
  end
end

loader = Zeitwerk::Loader.new
loader.inflector = DorServicesClientInflector.new
loader.push_dir('lib')
loader.setup

module Dor
  module Services
    class Client
      class Error < StandardError; end

      # Error that is raised when the remote server returns a 404 Not Found
      class NotFoundResponse < Error; end

      # Error that is raised when the remote server returns some unexpected response
      # this could be any 4xx or 5xx status
      class UnexpectedResponse < Error; end

      # Error that is raised when the remote server returns some unparsable response
      class MalformedResponse < Error; end

      class ConnectionFailed < Error; end

      DEFAULT_VERSION = 'v1'

      include Singleton

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

      def workflows
        @workflows ||= Workflows.new(connection: connection, version: DEFAULT_VERSION)
      end

      class << self
        # @param [String] url
        # @param [String] username
        # @param [String] password
        # @param [String] token a bearer token for HTTP auth
        # @param [String] token_header ('Authorization') set this to something if you are also using
        #                              basic auth, or the headers will collide
        def configure(url:, username: nil, password: nil, token: nil, token_header: 'Authorization')
          instance.url = url
          instance.username = username
          instance.password = password
          instance.token = token
          instance.token_header = token_header

          # Force connection to be re-established when `.configure` is called
          instance.connection = nil

          self
        end

        delegate :objects, :object, :workflows, to: :instance
      end

      attr_writer :url, :username, :password, :token, :token_header, :connection

      private

      attr_reader :username, :password, :token, :token_header

      def url
        @url || raise(Error, 'url has not yet been configured')
      end

      def connection
        @connection ||= Faraday.new(url) do |conn|
          conn.use ErrorFaradayMiddleware

          # @note when username & password are nil, this line is required else
          #       the Faraday instance will be passed an empty block, which
          #       causes the adapter not to be set. Thus, everything breaks.
          conn.adapter Faraday.default_adapter
          conn.basic_auth username, password if username && password
          conn.headers[:user_agent] = user_agent
          conn.headers[token_header] = "Bearer #{token}" if token
        end
      end

      def user_agent
        "dor-services-client #{Dor::Services::Client::VERSION}"
      end
    end
  end
end
