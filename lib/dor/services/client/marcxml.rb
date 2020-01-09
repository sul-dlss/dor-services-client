# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls around MARCXML-based operations from dor-services-app
      class Marcxml < VersionedService
        # Get a catkey corresponding to a barcode
        # @param barcode [String] required string representing a barcode
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        # @return [String] result of background job
        def catkey(barcode:)
          resp = connection.get do |req|
            req.url "#{api_version}/catalog/catkey"
            req.params['barcode'] = barcode
          end

          return resp.body if resp.success? && resp.body.present?
          raise NotFoundResponse if resp.success? && resp.body.blank?

          raise_exception_based_on_response!(resp)
        end
      end
    end
  end
end
