# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls around "virtual objects" in DOR
      class VirtualObjects < VersionedService
        # Create a batch of virtual objects in DOR
        # @param virtual_objects [Array] required array of virtual object params (see dor-services-app)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        # @return [String] URL from Location response header if no errors
        def create(virtual_objects:)
          resp = connection.post do |req|
            req.url "#{api_version}/virtual_objects"
            req.headers['Content-Type'] = 'application/json'
            req.headers['Accept'] = 'application/json'
            req.body = { virtual_objects: virtual_objects }.to_json
          end
          return resp.headers['Location'] if resp.success?

          raise_exception_based_on_response!(resp)
        end
      end
    end
  end
end
