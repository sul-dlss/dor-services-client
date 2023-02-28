# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls around MARCXML-based operations from dor-services-app
      class Marcxml < VersionedService
        # Gets MARCXML corresponding to a barcode or catkey
        # @param barcode [String] string representing a barcode
        # @param catkey [String] string representing a catkey
        # @param folio_instance_hrid [String] string representing a Folio instance HRID
        # @raise [NotFoundResponse] when the response is a 500 with "Record not found in Symphony"
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        # @return [String] MARCXML
        def marcxml(barcode: nil, catkey: nil, folio_instance_hrid: nil)
          check_args(barcode, catkey, folio_instance_hrid)

          resp = connection.get do |req|
            req.url "#{api_version}/catalog/marcxml"
            req.params['barcode'] = barcode unless barcode.nil?
            req.params['catkey'] = catkey unless catkey.nil?
            req.params['folio_instance_hrid'] = folio_instance_hrid unless folio_instance_hrid.nil?
          end

          # This method needs its own exception handling logic due to how the endpoint service (Symphony) operates

          # DOR Services App does not respond with a 404 when no match in Symphony or Folio.
          # Rather, it responds with a 500 containing "Record not found in catalog" in the body.
          # raise a NotFoundResponse because the resource being requested was not found in the ILS (via dor-services-app)
          raise NotFoundResponse.new(response: resp) if !resp.success? && resp.body.match?(/Record not found in catalog/)

          raise UnexpectedResponse.new(response: resp) unless resp.success?

          resp.body
        end

        private

        # rubocop:disable Layout/LineLength
        def check_args(barcode, catkey, folio_instance_hrid)
          raise ArgumentError, 'Barcode, catkey, or folio_instance_hrid must be provided' if barcode.nil? && catkey.nil? && folio_instance_hrid.nil?
          raise ArgumentError, 'Both barcode and a catalog id (catkey or folio_instance_hrid) may not be provided' if !barcode.nil? && (!catkey.nil? || !folio_instance_hrid.nil?)
        end
        # rubocop:enable Layout/LineLength
      end
    end
  end
end
