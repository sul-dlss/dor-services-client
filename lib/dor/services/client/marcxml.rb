# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls around MARCXML-based operations from dor-services-app
      class Marcxml < VersionedService
        # Gets MARCXML corresponding to a barcode or catkey
        # @param barcode [String] required string representing a barcode
        # @param catkey [String] required string representing a catkey
        # @raise [NotFoundResponse] when the response is a 500 with "Record not found in Symphony"
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        # @return [String] MARCXML
        def marcxml(barcode: nil, catkey: nil)
          check_args(barcode, catkey)

          resp = connection.get do |req|
            req.url "#{api_version}/catalog/marcxml"
            req.params['barcode'] = barcode unless barcode.nil?
            req.params['catkey'] = catkey unless catkey.nil?
          end

          # This method needs its own exception handling logic due to how the endpoint service (Symphony) operates

          # DOR Services App does not respond with a 404 when no match in Symphony.
          # Rather, it responds with a 500 containing "Record not found in Symphony" in the body.
          # raise a NotFoundResponse because the resource being requested was not found in the ILS (via dor-services-app)
          raise NotFoundResponse.new(response: resp) if !resp.success? && resp.body.match?(/Record not found in Symphony/)

          raise UnexpectedResponse.new(response: resp) unless resp.success?

          resp.body
        end

        private

        def check_args(barcode, catkey)
          raise ArgumentError, 'Barcode or catkey must be provided' if barcode.nil? && catkey.nil?
          raise ArgumentError, 'Both barcode and catkey may not be provided' if !barcode.nil? && !catkey.nil?
        end
      end
    end
  end
end
