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
        # @param [string] user_name the sunetid of the user registering the object
        # @param [boolean] validate validate the response object
        # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata] the returned model
        def register(params:, assign_doi: false, validate: false, user_name: nil) # rubocop:disable Metrics/AbcSize
          resp = connection.post do |req|
            req.url objects_path
            req.params = { assign_doi: assign_doi, user_name: user_name }.compact
            req.headers['Content-Type'] = 'application/json'
            # asking the service to return JSON (else it'll be plain text)
            req.headers['Accept'] = 'application/json'
            req.body = params.to_json
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          build_cocina_from_response(JSON.parse(resp.body), headers: resp.headers, validate: validate)
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

          build_cocina_from_response(JSON.parse(resp.body), headers: resp.headers, validate: validate)
        end

        # Find objects by a list of druids
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [Array<Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,,Cocina::Models::AdminPolicyWithMetadata>] the returned objects
        def find_all(druids:, validate: false) # rubocop:disable Metrics/AbcSize
          return [] if druids.empty?

          resp = connection.post do |req|
            req.url "#{objects_path}/find_all"
            req.headers['Content-Type'] = 'application/json'
            req.body = { 'externalIdentifiers' => druids }.to_json
          end
          raise_exception_based_on_response!(resp) unless resp.success?

          JSON.parse(resp.body).map do |item|
            # The ETag header is used as the lock parameter when instantiating a cocina model with metadata
            build_cocina_from_response(item, headers: { 'ETag' => item['lock'] }, validate: validate)
          end
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
