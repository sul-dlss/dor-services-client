# frozen_string_literal: true

require 'deprecation'

module Dor
  module Services
    class Client
      # API calls that are about a repository object
      class Object < VersionedService
        extend Deprecation
        attr_reader :object_identifier

        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, channel:, object_identifier:)
          raise ArgumentError, "The `object_identifier` parameter must be an identifier string: #{object_identifier.inspect}" unless object_identifier.is_a?(String)

          super(connection: connection, version: version, channel: channel)
          @object_identifier = object_identifier
        end

        def metadata
          @metadata ||= Metadata.new(**parent_params)
        end

        def events
          @events ||= Events.new(**parent_params_with_channel)
        end

        def workspace
          @workspace ||= Workspace.new(**parent_params)
        end

        def administrative_tags
          @administrative_tags ||= AdministrativeTags.new(**parent_params)
        end

        def version
          @version ||= ObjectVersion.new(**parent_params)
        end

        def accession(params = {})
          @accession ||= Accession.new(**parent_params.merge(params))
        end

        # Retrieves the Cocina model
        # @param [boolean] validate validate the response object
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata] the returned model
        def find(validate: false)
          resp = connection.get do |req|
            req.url object_path
          end
          raise_exception_based_on_response!(resp) unless resp.success?

          build_cocina_from_response(resp, validate: validate)
        end

        # Get a list of the collections. (Similar to Valkyrie's find_inverse_references_by)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return [Array<Cocina::Models::DRO>]
        def collections
          Collections.new(**parent_params).collections
        end

        # Get a list of the members
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return [Array<Members::Member>]
        def members
          Members.new(**parent_params).members
        end

        def transfer
          Transfer.new(**parent_params)
        end

        delegate :publish, :unpublish, :preserve, :shelve, to: :transfer

        def mutate
          Mutate.new(**parent_params)
        end

        delegate :refresh_descriptive_metadata_from_ils, :update, :destroy, :apply_admin_policy_defaults, to: :mutate

        alias refresh_metadata refresh_descriptive_metadata_from_ils
        deprecation_deprecate refresh_metadata: 'Use refresh_descriptive_metadata_from_ils instead'

        # Update the marc record for the given object
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def update_marc_record
          resp = connection.post do |req|
            req.url "#{object_path}/update_marc_record"
          end
          return true if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Update the DOI metadata at DataCite
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @return [boolean] true on success
        def update_doi_metadata
          resp = connection.post do |req|
            req.url "#{object_path}/update_doi_metadata"
          end
          return true if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Notify the external Goobi system for a new object that was registered in DOR
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def notify_goobi
          resp = connection.post do |req|
            req.url "#{object_path}/notify_goobi"
          end
          return true if resp.success?

          raise_exception_based_on_response!(resp)
        end

        private

        def parent_params
          { connection: connection, version: api_version, object_identifier: object_identifier }
        end

        def parent_params_with_channel
          parent_params.merge(channel: channel)
        end

        def object_path
          "#{api_version}/objects/#{object_identifier}"
        end
      end
    end
  end
end
