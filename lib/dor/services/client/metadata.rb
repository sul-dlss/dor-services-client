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

        # Updates using the legacy SDR/Fedora3 metadata
        # @param [Hash<Symbol,Hash>] opts the options for legacy update
        # @option opts [Hash] :descriptive Data for descriptive metadata
        # @option opts [Hash] :rights Data for access rights metadata
        # @option opts [Hash] :content Data for structural metadata
        # @option opts [Hash] :identity Data for identity metadata
        # @option opts [Hash] :technical Data for technical metadata
        # @option opts [Hash] :provenance Data for provenance metadata
        # @example:
        #  legacy_update(descriptive: { updated: '2001-12-20', content: '<descMetadata />' })
        def legacy_update(opts)
          opts = opts.slice(:descriptive, :rights, :identity, :content, :technical, :provenance)
          resp = connection.patch do |req|
            req.url "#{base_path}/legacy"
            req.headers['Content-Type'] = 'application/json'
            req.body = opts.to_json
          end
          return if resp.success?

          raise_exception_based_on_response!(resp, object_identifier)
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

        # @return [String, NilClass] The descriptive metadata XML representation of the object or nil if response is 404
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        def descriptive
          resp = connection.get do |req|
            req.url "#{base_path}/descriptive"
          end
          return resp.body if resp.success?
          return if resp.status == 404

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
