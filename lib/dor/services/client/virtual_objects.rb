# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls around "virtual objects" in DOR
      class VirtualObjects < VersionedService
        # Create a batch of virtual objects in DOR
        # @param params [Hash] required hash params (see dor-services-app)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        # @return [NilClass] nil if no errors
        def create(params:)
          resp = connection.post do |req|
            req.url "#{api_version}/virtual_objects"
            req.headers['Content-Type'] = 'application/json'
            req.headers['Accept'] = 'application/json'
            req.body = params.to_json
          end
          return if resp.success?

          raise_exception_based_on_response!(resp)
        end

        private

        def raise_exception_based_on_response!(response)
          raise (response.status == 404 ? NotFoundResponse : UnexpectedResponse),
                ResponseErrorFormatter.format(response: response)
        end
      end
    end
  end
end
