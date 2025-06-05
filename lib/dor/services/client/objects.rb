# frozen_string_literal: true

require 'deprecation'

module Dor
  module Services
    class Client
      # API calls that are about repository objects
      class Objects < VersionedService
        # Creates a new object in DOR
        # @param params [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAdminPolicy]
        # @param [boolean] assign a doi to the object
        # @param [string] who the sunetid of the user registering the object
        # @param [boolean] validate validate the response object
        # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata] the returned model
        def register(params:, assign_doi: false, validate: false, who: nil)
          resp = connection.post do |req|
            req.url objects_path
            req.params = { assign_doi: assign_doi, event_who: who }.compact
            req.headers['Content-Type'] = 'application/json'
            # asking the service to return JSON (else it'll be plain text)
            req.headers['Accept'] = 'application/json'
            req.body = params.to_json
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          build_cocina_from_response(resp, validate: validate)
        end

        # Find an object by source ID
        # @param [boolean] validate validate the response object
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata] the returned object
        def find(source_id:, validate: false)
          resp = connection.get do |req|
            req.url "#{objects_path}/find"
            req.params['sourceId'] = source_id
          end
          raise_exception_based_on_response!(resp) unless resp.success?

          build_cocina_from_response(resp, validate: validate)
        end

        # Retrieves the version statuses for a batch of objects
        # @param [Array<String>] object_ids the druids to get statuses for
        # @return [Hash<String,VersionStatus>] Map of druids to statuses
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        def statuses(object_ids:)
          resp = connection.post do |req|
            req.url "#{objects_path}/versions/status"
            req.headers['Content-Type'] = 'application/json'
            req.body = { externalIdentifiers: object_ids }.to_json
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          JSON.parse(resp.body).transform_values { |status| ObjectVersion::VersionStatus.new(status.symbolize_keys!) }
        end

        private

        def objects_path
          "#{api_version}/objects"
        end
      end
    end
  end
end
