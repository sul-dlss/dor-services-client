# frozen_string_literal: true

require 'dor/services/client/version'
require 'singleton'
require 'faraday'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/module/delegation'
require 'dor/services/client/versioned_service'
require 'dor/services/client/files'
require 'dor/services/client/objects'
require 'dor/services/client/release_tags'
require 'dor/services/client/workflow'
require 'dor/services/client/workspace'

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

      def objects
        @objects ||= Objects.new(connection: connection, version: DEFAULT_VERSION)
      end

      def files
        @files ||= Files.new(connection: connection, version: DEFAULT_VERSION)
      end

      def workflow
        @workflow ||= Workflow.new(connection: connection, version: DEFAULT_VERSION)
      end

      def workspace
        @workspace ||= Workspace.new(connection: connection, version: DEFAULT_VERSION)
      end

      def release_tags
        @release_tags ||= ReleaseTags.new(connection: connection, version: DEFAULT_VERSION)
      end

      class << self
        def configure(url:, username: nil, password: nil)
          instance.url = url
          instance.username = username
          instance.password = password
          # Force connection to be re-established when `.configure` is called
          instance.connection = nil
        end

        delegate :objects, :files, :workflow, :workspace, :release_tags, to: :instance
        private :objects, :files, :workflow, :workspace, :release_tags

        # Creates a new object in DOR
        # @return [HashWithIndifferentAccess] the response, which includes a :pid
        delegate :register, to: :objects

        # @param [String] object the identifier for the object
        # @param [String] filename the name of the file to retrieve
        # @return [String] the file contents from the workspace
        def retrieve_file(object:, filename:)
          files.retrieve(object: object, filename: filename)
        end

        # Get the preserved file contents
        # @param [String] object the identifier for the object
        # @param [String] filename the name of the file to retrieve
        # @param [Integer] version the version of the file to retrieve
        # @return [String] the file contents from the SDR
        delegate :preserved_content, to: :files

        # @param [String] object the identifier for the object
        # @return [Array<String>] the list of filenames in the workspace
        def list_files(object:)
          files.list(object: object)
        end

        # Initializes a new workflow
        # @param object [String] the pid for the object
        # @param wf_name [String] the name of the workflow
        # @raises [UnexpectedResponse] if the request is unsuccessful.
        # @return nil
        def initialize_workflow(object:, wf_name:)
          workflow.create(object: object, wf_name: wf_name)
        end

        # Initializes a new workspace
        # @param object [String] the pid for the object
        # @param source [String] the path to the object
        # @raises [UnexpectedResponse] if the request is unsuccessful.
        # @return nil
        def initialize_workspace(object:, source:)
          workspace.create(object: object, source: source)
        end

        # Creates a new release tag for the object
        # @param object [String] the pid for the object
        # @param release [Boolean]
        # @param what [String]
        # @param to [String]
        # @param who [String]
        # @return [Boolean] true if successful
        def create_release_tag(object:, release:, what:, to:, who:)
          release_tags.create(object: object, release: release, what: what, to: to, who: who)
        end

        # Publish a new object
        # @param object [String] the pid for the object
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        delegate :publish, to: :objects
      end

      # Gets the current version number for the object
      # @param object [String] the pid for the object
      # @raise [UnexpectedResponse] when the response is not successful.
      # @raise [MalformedResponse] when the response is not parseable.
      # @return [Integer] the current version
      def self.current_version(object:)
        instance.objects.current_version(object: object)
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
