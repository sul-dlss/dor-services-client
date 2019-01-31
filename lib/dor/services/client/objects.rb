# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about a repository objects
      class Objects < VersionedService
        # Find and return an object by its ID
        def find_by(id:)
          resp = connection.get do |req|
            req.url "#{api_version}/objects/#{id}"
            req.headers['Content-Type'] = 'application/json'
            # asking the service to return JSON (else it'll be plain text)
            req.headers['Accept'] = 'application/json'
          end
          return JSON.parse(resp.body).with_indifferent_access if resp.success?

          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})"
        end

        # Find and return objects given a model
        def find_all_of_model(model:)
          resp = connection.get do |req|
            req.url "#{api_version}/objects/all/#{model}"
            req.headers['Content-Type'] = 'application/json'
            # asking the service to return JSON (else it'll be plain text)
            req.headers['Accept'] = 'application/json'
          end
          return JSON.parse(resp.body) if resp.success?

          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})"
        end

        # Creates a new object in DOR
        # @return [HashWithIndifferentAccess] the response, which includes a :pid
        def register(params:)
          json = register_response(params: params)
          JSON.parse(json).with_indifferent_access
        end

        private

        # make the registration request to the server
        # @param params [Hash] optional params (see dor-services-app)
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
