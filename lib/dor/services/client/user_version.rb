# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about user versions
      class UserVersion < VersionedService
        Version = Struct.new(:version, :userVersion, :withdrawn, keyword_init: true)

        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # @return [Array] a list of the user versions
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        def inventory
          resp = connection.get do |req|
            req.url base_path
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          JSON.parse(resp.body).fetch('user_versions').map { |params| Version.new(**params.symbolize_keys!) }
        end

        # @return [Cocina::Models::DROWithMetadata] the object metadata
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        def find(version)
          resp = connection.get do |req|
            req.url "#{base_path}/#{version}"
          end
          raise_exception_based_on_response!(resp) unless resp.success?

          build_cocina_from_response(resp, validate: false)
        end

        # Create a user version for an object
        #
        # @param [String] object_version the version of the object to create a user version for
        # @return [Version]
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        def create(object_version:)
          resp = connection.post do |req|
            req.url "#{api_version}/objects/#{object_identifier}/user_versions"
            req.headers['Content-Type'] = 'application/json'
            req.body = { version: object_version }.to_json
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          Version.new(**JSON.parse(resp.body).symbolize_keys!)
        end

        # Updates a user version
        #
        # @param [Version] user_version the updated user version
        # @return [Version]
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # rubocop:disable Metrics/AbcSize
        def update(user_version:)
          resp = connection.patch do |req|
            req.url "#{api_version}/objects/#{object_identifier}/user_versions/#{user_version.userVersion}"
            req.headers['Content-Type'] = 'application/json'
            req.body = user_version.to_h.except(:userVersion).compact.to_json
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          Version.new(**JSON.parse(resp.body).symbolize_keys!)
        end
        # rubocop:enable Metrics/AbcSize

        private

        attr_reader :object_identifier

        def object_path
          "#{api_version}/objects/#{object_identifier}"
        end

        def base_path
          "#{object_path}/user_versions"
        end
      end
    end
  end
end
