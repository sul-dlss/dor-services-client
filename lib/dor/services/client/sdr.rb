# frozen_string_literal: true

require 'nokogiri'

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
          "#{api_version}/sdr/objects/#{object_identifier}/current_version"
        end
      end
    end
  end
end
