# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about a repository objects
      class Objects < VersionedService
        # Creates a new object in DOR
        # @return [HashWithIndifferentAccess] the response, which includes a :pid
        def register(params:)
          json = register_response(params: params)
          JSON.parse(json).with_indifferent_access
        end

        private

        # make the registration request to the server
        # @param params [Hash] optional params (see dor-services-app)
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        # @return [String] the raw JSON from the server
        def register_response(params:)
          resp = connection.post do |req|
            req.url "#{api_version}/objects"
            req.headers['Content-Type'] = 'application/json'
            # asking the service to return JSON (else it'll be plain text)
            req.headers['Accept'] = 'application/json'
            req.body = params.to_json
          end
          return resp.body if resp.success?

          raise UnexpectedResponse, ResponseErrorFormatter.format(response: resp)
        end
      end
    end
  end
end
