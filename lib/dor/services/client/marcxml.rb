# frozen_string_literal: true

require 'nokogiri'

module Dor
  module Services
    class Client
      # API calls around MARCXML-based operations from dor-services-app
      class Marcxml < VersionedService
        # Get a catkey corresponding to a barcode
        # @param barcode [String] required string representing a barcode
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        # @return [String] catkey
        def catkey(barcode:)
          resp = connection.get do |req|
            req.url "#{api_version}/catalog/catkey"
            req.params['barcode'] = barcode
          end

          return resp.body if resp.success? && resp.body.present?

          # This method needs its own exception handling logic due to how the endpoint service (SearchWorks) operates
          # raise a NotFoundResponse because the resource being requested was not found in the ILS (via dor-services-app)
          raise NotFoundResponse.new(resp, barcode) if resp.success? && resp.body.blank?

          raise UnexpectedResponse.new(resp, barcode)
        end

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

          return resp.body if resp.success?

          # This method needs its own exception handling logic due to how the endpoint service (Symphony) operates
          identifier = barcode.presence || catkey
          # DOR Services App does not respond with a 404 when no match in Symphony.
          # Rather, it responds with a 500 containing "Record not found in Symphony" in the body.
          # raise a NotFoundResponse because the resource being requested was not found in the ILS (via dor-services-app)
          raise NotFoundResponse.new(resp, identifier) if resp.body.match?(/Record not found in Symphony/)

          raise UnexpectedResponse.new(resp, identifier)
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
