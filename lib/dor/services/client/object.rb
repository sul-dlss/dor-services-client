# frozen_string_literal: true

require 'deprecation'

module Dor
  module Services
    class Client
      # API calls that are about a repository object
      class Object < VersionedService # rubocop:disable Metrics/ClassLength
        extend Deprecation
        attr_reader :object_identifier

        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          raise ArgumentError, "The `object_identifier` parameter must be an identifier string: #{object_identifier.inspect}" unless object_identifier.is_a?(String)

          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        def events
          @events ||= Events.new(**parent_params)
        end

        def workspace
          @workspace ||= Workspace.new(**parent_params)
        end

        def administrative_tags
          @administrative_tags ||= AdministrativeTags.new(**parent_params)
        end

        def release_tags
          @release_tags ||= ReleaseTags.new(**parent_params)
        end

        def version
          @version ||= ObjectVersion.new(**parent_params)
        end

        def user_version
          @user_version ||= UserVersion.new(**parent_params)
        end

        def accession(params = {})
          @accession ||= Accession.new(**parent_params.merge(params))
        end

        def milestones
          @milestones ||= Milestones.new(**parent_params)
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

        BASE_ALLOWED_FIELDS = %i[external_identifier cocina_version label version administrative description].freeze
        DRO_ALLOWED_FIELDS = BASE_ALLOWED_FIELDS + %i[content_type access identification structural geographic]

        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/ParameterLists
        def find_lite(administrative: true, description: true, access: true, structural: true, identification: true, geographic: true)
          fields = []
          fields << :administrative if administrative
          fields << :description if description
          fields << :access if access
          fields << :structural if structural
          fields << :identification if identification
          fields << :geographic if geographic

          resp = connection.post '/graphql', query(fields),
                                 'Content-Type' => 'application/json'
          raise_exception_based_on_response!(resp) unless resp.success?
          resp_json = JSON.parse(resp.body)
          # GraphQL returns 200 even when an error
          raise_graphql_exception(resp, resp_json)
          Cocina::Models.build_lite(resp_json['data']['cocinaObject'])
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/CyclomaticComplexity
        # rubocop:enable Metrics/ParameterLists

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

        def mutate
          Mutate.new(**parent_params)
        end

        delegate :refresh_descriptive_metadata_from_ils, :update, :destroy, :apply_admin_policy_defaults, to: :mutate

        alias refresh_metadata refresh_descriptive_metadata_from_ils
        deprecation_deprecate refresh_metadata: 'Use refresh_descriptive_metadata_from_ils instead'

        # Reindex the object in Solr.
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def reindex
          resp = connection.post do |req|
            req.url "#{object_path}/reindex"
          end
          return true if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Publish an object (send to PURL)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @param [String] workflow (nil) which workflow to callback to.
        # @param [String] lane_id for prioritization (default or low)
        # @return [String] the URL of the background job on dor-service-app
        # rubocop:disable Metrics/MethodLength
        def publish(workflow: nil, lane_id: nil)
          query_params = [].tap do |params|
            params << "workflow=#{workflow}" if workflow
            params << "lane-id=#{lane_id}" if lane_id
          end
          query_string = query_params.any? ? "?#{query_params.join('&')}" : ''
          publish_path = "#{object_path}/publish#{query_string}"
          resp = connection.post do |req|
            req.url publish_path
          end
          return resp.headers['Location'] if resp.success?

          raise_exception_based_on_response!(resp)
        end
        # rubocop:enable Metrics/MethodLength

        private

        def parent_params
          { connection: connection, version: api_version, object_identifier: object_identifier }
        end

        def object_path
          "#{api_version}/objects/#{object_identifier}"
        end

        DEFAULT_FIELDS = %i[externalIdentifier type version label cocinaVersion].freeze

        def query(fields)
          all_fields = DEFAULT_FIELDS + fields
          {
            query:
          <<~GQL
            {
              cocinaObject(externalIdentifier: "#{object_identifier}") {
                #{all_fields.join("\n")}
              }
            }
          GQL
          }.to_json
        end

        def raise_graphql_exception(resp, resp_json)
          return unless resp_json['errors'].present?

          exception_class = not_found_exception?(resp_json['errors'].first) ? NotFoundResponse : UnexpectedResponse
          raise exception_class.new(response: resp,
                                    object_identifier: object_identifier,
                                    graphql_errors: resp_json['errors'])
        end

        def not_found_exception?(error)
          error['message'] == 'Cocina object not found'
        end
      end
    end
  end
end
