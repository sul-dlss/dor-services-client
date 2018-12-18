# frozen_string_literal: true

require 'dor/services/client/version'
require 'singleton'
require 'faraday'
require 'active_support/core_ext/hash/indifferent_access'
require 'dor/services/client/files'
require 'dor/services/client/objects'

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
