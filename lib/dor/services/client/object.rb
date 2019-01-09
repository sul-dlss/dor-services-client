# frozen_string_literal: true

require 'nokogiri'
require 'deprecation'

module Dor
  module Services
    class Client
      # API calls that are about a repository object
      class Object < VersionedService
        # @param object [String] the pid for the object
        def initialize(connection:, version:, object:)
          super(connection: connection, version: version)
          @object = object
        end

        # Publish a new object
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def publish
          resp = connection.post do |req|
            req.url "#{api_version}/objects/#{object}/publish"
          end
          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?

          true
        end

        # Notify the external Goobi system for a new object that was registered in DOR
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def notify_goobi
          resp = connection.post do |req|
            req.url "#{object_path}/notify_goobi"
          end
          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?

          true
        end

        # Get the current_version for a DOR object. This comes from Dor::VersionMetadataDS
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [String] the version identifier
        def current_version
          resp = connection.get do |req|
            req.url "#{object_path}/versions/current"
          end
          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?

          resp.body
        end

        private

        attr_reader :object

        def object_path
          "#{api_version}/objects/#{object}"
        end
      end
    end
  end
end
