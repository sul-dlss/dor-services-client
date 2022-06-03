# frozen_string_literal: true

require 'deprecation'

module Dor
  module Services
    class Client
      # API calls that are about a repository objects
      class Objects < VersionedService
        # Creates a new object in DOR
        # @param params [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy]
        # @param assign_doi [Boolean]
        # @param [boolean] validate validate the response object
        # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata] the returned model
        def register(params:, assign_doi: false, validate: false)
          resp = connection.post do |req|
            req.url "#{api_version}/objects"
            req.headers['Content-Type'] = 'application/json'
            # asking the service to return JSON (else it'll be plain text)
            req.headers['Accept'] = 'application/json'
            req.params[:assign_doi] = true if assign_doi
            req.body = params.to_json
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          build_cocina_from_response(resp, validate: validate)
        end

        def to_index
          resp = connection.get do |req|
            req.url "#{api_version}/druid_list"
            req.headers['Accept'] = 'text/plain'
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          resp.body
        end
      end
    end
  end
end
