# frozen_string_literal: true

require 'nokogiri'
require 'moab'

module Dor
  module Services
    class Client
      # API calls that are about preserved objects
      class SDR < VersionedService
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Gets the current version number for the object
        # @raise [UnexpectedResponse] when the response is not successful.
        # @raise [MalformedResponse] when the response is not parseable.
        # @return [Integer] the current version
        def current_version
          xml = current_version_response
          begin
            doc = Nokogiri::XML xml
            raise if doc.root.name != 'currentVersion'

            return Integer(doc.text)
          rescue StandardError
            raise MalformedResponse, "Unable to parse XML from current_version API call: #{xml}"
          end
        end

        def signature_catalog
          resp = connection.get do |req|
            req.url "#{base_path}/manifest/signatureCatalog.xml"
          end

          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body}) for #{object_identifier}" unless resp.success?

          Moab::SignatureCatalog.parse resp.body
        end

        # Retrieves file difference manifest for contentMetadata from SDR
        #
        # @param [String] current_content The contentMetadata xml
        # @param [String] subset ('all') The keyword for file attributes 'shelve', 'preserve', 'publish'.
        # @param [Integer, NilClass] version (nil)
        # @return [Moab::FileInventoryDifference] the differences for the given content and subset (i.e.: cm_inv_diff manifest)
        def content_diff(current_content:, subset: 'all', version: nil)
          raise ArgumentError, "Invalid subset value: #{subset}" unless %w[all shelve preserve publish].include?(subset)

          query_string = { subset: subset }
          query_string[:version] = version.to_s unless version.nil?
          query_string = URI.encode_www_form(query_string)

          resp = connection.post do |req|
            req.url "#{base_path}/cm-inv-diff?#{query_string}"
            req.headers['Content-Type'] = 'application/xml'
            req.body = current_content
          end
          Moab::FileInventoryDifference.parse(resp.body)
        end

        private

        attr_reader :object_identifier

        # make the request to the server for the currentVersion xml
        # @raises [UnexpectedResponse] on an unsuccessful response from the server
        # @returns [String] the raw xml from the server
        def current_version_response
          resp = connection.get do |req|
            req.url current_version_path
          end
          return resp.body if resp.success?

          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body}) for #{object_identifier}"
        end

        def current_version_path
          "#{base_path}/current_version"
        end

        def base_path
          "#{api_version}/sdr/objects/#{object_identifier}"
        end
      end
    end
  end
end
