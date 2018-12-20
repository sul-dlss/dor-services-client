# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about a repository object
      class Objects < VersionedService
        # Creates a new object in DOR
        # @return [HashWithIndifferentAccess] the response, which includes a :pid
        def register(params:)
          resp = connection.post do |req|
            req.url "#{version}/objects"
            req.headers['Content-Type'] = 'application/json'
            # asking the service to return JSON (else it'll be plain text)
            req.headers['Accept'] = 'application/json'
            req.body = params.to_json
          end
          raise Error, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?

          JSON.parse(resp.body).with_indifferent_access
        end

        # Publish a new object
        # @param object [String] the pid for the object
        # @raise [Error] when the response is not successful.
        # @return [boolean] true on success
        def publish(object:)
          resp = connection.post do |req|
            req.url "#{version}/objects/#{object}/publish"
          end
          raise Error, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?

          true
        end
      end
    end
  end
end
