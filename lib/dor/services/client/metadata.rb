# frozen_string_literal: true

require 'active_support/json' # required for serializing time as iso8601

module Dor
  module Services
    class Client
      # API calls that are about retrieving metadata
      class Metadata < VersionedService
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # @return [String, NilClass] The Dublin Core XML representation of the object or nil if response is 404
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        def dublin_core
          resp = connection.get do |req|
            req.url "#{base_path}/dublin_core"
          end
          return resp.body if resp.success?
          return if resp.status == 404

          raise_exception_based_on_response!(resp, object_identifier)
        end

        # @return [String, NilClass] The public descriptive metadata XML representation of the object or nil if response is 404
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        def descriptive
          resp = connection.get do |req|
            req.url "#{base_path}/descriptive"
          end
          return resp.body if resp.success?
          return if resp.status == 404

          raise_exception_based_on_response!(resp, object_identifier)
        end

        # @return [String, NilClass] The public XML representation of the object or nil if response is 404
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        def public_xml
          resp = connection.get do |req|
            req.url "#{base_path}/public_xml"
          end
          return resp.body if resp.success?
          return if resp.status == 404

          raise_exception_based_on_response!(resp, object_identifier)
        end

        # @return [String, NilClass] the dor object's source MODS XML or nil if response is 404
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        def mods
          resp = connection.get do |req|
            req.url "#{base_path}/mods"
          end
          return resp.body if resp.success?
          return if resp.status == 404

          raise_exception_based_on_response!(resp, object_identifier)
        end

        # Update the MODS XML metadata
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @return [boolean] true on success
        def update_mods(mods_xml)
          resp = connection.put do |req|
            req.url "#{base_path}/mods"
            req.headers['Content-Type'] = 'application/xml'
            req.body = mods_xml
          end
          return if resp.success?

          raise_exception_based_on_response!(resp, object_identifier)
        end

        private

        attr_reader :object_identifier

        def base_path
          "#{api_version}/objects/#{object_identifier}/metadata"
        end
      end
    end
  end
end
