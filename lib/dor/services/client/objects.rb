# frozen_string_literal: true

require 'nokogiri'

module Dor
  module Services
    class Client
      # API calls that are about a repository objects
      class Objects < VersionedService
        extend Deprecation

        # Creates a new object in DOR
        # @return [HashWithIndifferentAccess] the response, which includes a :pid
        def register(params:)
          json = register_response(params: params)
          JSON.parse(json).with_indifferent_access
        end

        # Publish a new object
        # @param object [String] the pid for the object
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def publish(object:)
          Object.new(connection: connection, version: api_version, object: object).publish
        end
        deprecation_deprecate publish: 'Use Dor::Client.object(obj).publish instead'

        # Notify the external Goobi system for a new object that was registered in DOR
        # @param object [String] the pid for the object
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def notify_goobi(object:)
          Object.new(connection: connection, version: api_version, object: object).notify_goobi
        end
        deprecation_deprecate notify_goobi: 'Use Dor::Client.object(obj).notify_goobi instead'

        # Gets the current version number for the object
        # @param object [String] the pid for the object
        # @raise [UnexpectedResponse] when the response is not successful.
        # @raise [MalformedResponse] when the response is not parseable.
        # @return [Integer] the current version
        def current_version(object:)
          SDR.new(connection: connection, version: api_version).current_version(object: object)
        end
        deprecation_deprecate current_version: 'Use Dor::Client.sdr.current_version instead'

        private

        # make the registration request to the server
        # @raises [UnexpectedResponse] on an unsuccessful response from the server
        # @returns [String] the raw JSON from the server
        def register_response(params:)
          resp = connection.post do |req|
            req.url "#{api_version}/objects"
            req.headers['Content-Type'] = 'application/json'
            # asking the service to return JSON (else it'll be plain text)
            req.headers['Accept'] = 'application/json'
            req.body = params.to_json
          end
          return resp.body if resp.success?

          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})"
        end
      end
    end
  end
end
