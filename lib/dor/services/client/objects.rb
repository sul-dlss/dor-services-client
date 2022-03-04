# frozen_string_literal: true

require 'deprecation'

module Dor
  module Services
    class Client
      # API calls that are about a repository objects
      class Objects < VersionedService
        # Creates a new object in DOR
        # @param params [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAPO]
        # @param assign_doi [Boolean]
        # @return [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAPO] the returned model
        def register(params:, assign_doi: false)
          resp = connection.post do |req|
            req.url "#{api_version}/objects"
            req.headers['Content-Type'] = 'application/json'
            # asking the service to return JSON (else it'll be plain text)
            req.headers['Accept'] = 'application/json'
            req.params[:assign_doi] = true if assign_doi
            req.body = params.to_json
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          build_cocina_from_response(resp)
        end
      end
    end
  end
end
