# frozen_string_literal: true

require 'dor/services/client/version'
require 'singleton'
require 'faraday'
require 'active_support/core_ext/hash/indifferent_access'
require 'dor/services/client/files'
require 'dor/services/client/objects'
require 'dor/services/client/release_tags'
require 'dor/services/client/workflow'
require 'dor/services/client/workspace'

module Dor
  module Services
    class Client
      class Error < StandardError; end

      include Singleton

      def objects
        @objects ||= Objects.new(connection: connection)
      end

      def files
        @files ||= Files.new(connection: connection)
      end

      def workflow
        @workflow ||= Workflow.new(connection: connection)
      end

      def workspace
        @workspace ||= Workspace.new(connection: connection)
      end

      def release_tags
        @release_tags ||= ReleaseTags.new(connection: connection)
      end

      def self.configure(url:)
        instance.url = url
      end

      # Creates a new object in DOR
      # @return [HashWithIndifferentAccess] the response, which includes a :pid
      def self.register(params:)
        instance.objects.register(params: params)
      end

      # @param [String] object the identifier for the object
      # @param [String] filename the name of the file to retrieve
      # @return [String] the file contents from the workspace
      def self.retrieve_file(object:, filename:)
        instance.files.retrieve(object: object, filename: filename)
      end

      # @param [String] object the identifier for the object
      # @return [Array<String>] the list of filenames in the workspace
      def self.list_files(object:)
        instance.files.list(object: object)
      end

      # Initializes a new workflow
      # @param object [String] the pid for the object
      # @param wf_name [String] the name of the workflow
      # @raises [Error] if the request is unsuccessful.
      # @return nil
      def self.initialize_workflow(object:, wf_name:)
        instance.workflow.create(object: object, wf_name: wf_name)
      end

      # Initializes a new workspace
      # @param object [String] the pid for the object
      # @param source [String] the path to the object
      # @raises [Error] if the request is unsuccessful.
      # @return nil
      def self.initialize_workspace(object:, source:)
        instance.workspace.create(object: object, source: source)
      end

      # Creates a new release tag for the object
      # @param object [String] the pid for the object
      # @param release [Boolean]
      # @param what [String]
      # @param to [String]
      # @param who [String]
      # @return [Boolean] true if successful
      def self.create_release_tag(object:, release:, what:, to:, who:)
        instance.release_tags.create(object: object, release: release, what: what, to: to, who: who)
      end

      attr_writer :url

      private

      def url
        @url || raise(Error, 'url has not yet been configured')
      end

      def connection
        @connection ||= Faraday.new(url)
      end
    end
  end
end
