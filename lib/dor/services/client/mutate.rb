# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that update the data.
      class Mutate < VersionedService
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Copies the values from the admin policy to the item
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def apply_admin_policy_defaults
          resp = connection.post do |req|
            req.url "#{object_path}/apply_admin_policy_defaults"
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          true
        end

        # Updates the object
        # @param [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata|DRO|Collection|AdminPolicy] params model object
        # @param [boolean] skip_lock do not provide ETag
        # @param [boolean] validate validate the response object
        # @param [string] user_name the sunetid of the user performing the update
        # @param [string] description a description of the update
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @raise [BadRequestError] when ETag not provided.
        # @return [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Models::AdminPolicyWithMetadata] the returned model
        # rubocop:disable Metrics/AbcSize
        # rubocop:disable Metrics/MethodLength
        def update(params:, skip_lock: false, validate: false, user_name: nil, description: nil)
          raise ArgumentError, 'Cocina object not provided.' unless params.respond_to?(:externalIdentifier)

          # Raised if Cocina::Models::*WithMetadata not provided.
          raise ArgumentError, 'ETag not provided.' unless skip_lock || params.respond_to?(:lock)

          resp = connection.patch do |req|
            req.url object_path
            req.params = { event_description: description, user_name: user_name }.compact
            req.headers['Content-Type'] = 'application/json'
            # asking the service to return JSON (else it'll be plain text)
            req.headers['Accept'] = 'application/json'
            req.headers['If-Match'] = params.lock unless skip_lock
            req.body = build_json_from_cocina(params)
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          build_cocina_from_response(resp, validate: validate)
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength

        # Pull in metadata from Symphony and updates descriptive metadata
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def refresh_descriptive_metadata_from_ils
          resp = connection.post do |req|
            req.url "#{object_path}/refresh_metadata"
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          true
        end

        # Destroys an object
        # @param [String] user_name (nil) the user name of the user doing the destroy
        # @return [Boolean] true if successful
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        def destroy(user_name: nil)
          resp = connection.delete do |req|
            req.url object_path
            req.params = { user_name: user_name }.compact
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          true
        end

        private

        def object_path
          "#{api_version}/objects/#{object_identifier}"
        end

        attr_reader :object_identifier
      end
    end
  end
end
