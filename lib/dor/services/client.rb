# frozen_string_literal: true

require 'dor/services/client/version'
require 'singleton'
require 'faraday'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/module/delegation'
require 'dor/services/client/versioned_service'
require 'dor/services/client/object'
require 'dor/services/client/objects'

module Dor
  module Services
    class Client
      class Error < StandardError; end

      # Error that is raised when the remote server returns some unexpected response
      # this could be any 4xx or 5xx status.
      class UnexpectedResponse < Error; end

      # Error that is raised when the remote server returns some unparsable response
      class MalformedResponse < Error; end

      DEFAULT_VERSION = 'v1'

      include Singleton

      def object(object_identifier)
        Object.new(connection: connection, version: DEFAULT_VERSION, object_id: object_identifier)
      end

      def objects
        @objects ||= Objects.new(connection: connection, version: DEFAULT_VERSION)
      end

      class << self
        def configure(url:, username: nil, password: nil)
          instance.url = url
          instance.username = username
          instance.password = password
          # Force connection to be re-established when `.configure` is called
          instance.connection = nil

          self
        end

        delegate :objects, :object, to: :instance
      end

      attr_writer :url, :username, :password, :connection

      private

      attr_reader :username, :password

      def url
        @url || raise(Error, 'url has not yet been configured')
      end

      def connection
        @connection ||= Faraday.new(url) do |conn|
          # @note when username & password are nil, this line is required else
          #       the Faraday instance will be passed an empty block, which
          #       causes the adapter not to be set. Thus, everything breaks.
          conn.adapter    Faraday.default_adapter
          conn.basic_auth username, password if username && password
        end
      end
    end
  end
end
