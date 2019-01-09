# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about preserved objects
      class SDR < VersionedService
        # Gets the current version number for the object
        # @param object [String] the pid for the object
        # @raise [UnexpectedResponse] when the response is not successful.
        # @raise [MalformedResponse] when the response is not parseable.
        # @return [Integer] the current version
        def current_version(object:)
          xml = current_version_response(object: object)
          begin
            doc = Nokogiri::XML xml
            raise if doc.root.name != 'currentVersion'

            return Integer(doc.text)
          rescue StandardError
            raise MalformedResponse, "Unable to parse XML from current_version API call: #{xml}"
          end
        end

        private

        # make the request to the server for the currentVersion xml
        # @raises [UnexpectedResponse] on an unsuccessful response from the server
        # @returns [String] the raw xml from the server
        def current_version_response(object:)
          resp = connection.get do |req|
            req.url current_version_path(object: object)
          end
          return resp.body if resp.success?

          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body}) for #{object}"
        end

        def current_version_path(object:)
          "#{api_version}/sdr/objects/#{object}/current_version"
        end
      end
    end
  end
end
