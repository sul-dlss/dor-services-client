# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about versions
      class ObjectVersion < VersionedService
        Version = Struct.new(:versionId, :message, keyword_init: true)
        VersionStatus = Struct.new(:versionId, :open, :openable, :assembling, :text_extracting, :accessioning, :closeable, keyword_init: true) do
          alias_method :version, :versionId

          def open?
            open
          end

          def openable?
            openable
          end

          def assembling?
            assembling
          end

          def text_extracting?
            text_extracting
          end

          def accessioning?
            accessioning
          end

          def closed?
            !open
          end

          def closeable?
            closeable
          end
        end

        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Get the current version for a DOR object. This comes from ObjectVersion table in the DSA
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [String] the version identifier
        def current
          resp = connection.get do |req|
            req.url "#{base_path}/current"
          end
          return resp.body if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Determines if a new version can be opened for a DOR object.
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [Boolean] true if a new version can be opened
        # rubocop:disable Metrics/MethodLength
        def openable?
          resp = connection.get do |req|
            req.url "#{base_path}/openable"
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          case resp.body
          when 'true'
            true
          when 'false'
            false
          else
            raise MalformedResponse, "Expected true or false, not #{resp.body}"
          end
        end
        # rubocop:enable Metrics/MethodLength

        # Open new version for an object
        # @param description [String] a description of the object version being opened - required
        # @param opening_user_name [String] sunetid - defaults to nil
        # @param assume_accessioned [Boolean] if true, does not check whether object has been accessioned; defaults to false
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina model with updated version
        def open(**params)
          resp = connection.post do |req|
            req.url with_querystring(url: open_new_version_path, params: params)
            req.headers['Content-Type'] = 'application/json'
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          build_cocina_from_response(resp)
        end

        # Close current version for an object
        # @param description [String] (optional) - a description of the object version being opened
        # @param user_name [String] (optional) - sunetid
        # @param start_accession [Boolean] (optional) - whether to start accessioning workflow; defaults to true
        # @param user_versions [String] (optional - values are none, new, or update) - create, update, or do nothing with user versions on close; defaults to none.
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [String] a message confirming successful closing
        def close(**params)
          resp = connection.post do |req|
            req.url with_querystring(url: close_version_path, params: params)
            req.headers['Content-Type'] = 'application/json'
          end
          return resp.body if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # @return [Array] a list of the versions
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        def inventory
          resp = connection.get do |req|
            req.url base_path
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          JSON.parse(resp.body).fetch('versions').map { |params| Version.new(**params.symbolize_keys!) }
        end

        # @return [VersionStatus] status of the version
        # @raise [UnexpectedResponse] on an unsuccessful response from the server
        def status
          resp = connection.get do |req|
            req.url "#{base_path}/status"
          end
          raise_exception_based_on_response!(resp, object_identifier) unless resp.success?

          VersionStatus.new(JSON.parse(resp.body).symbolize_keys!)
        end

        private

        attr_reader :object_identifier

        def object_path
          "#{api_version}/objects/#{object_identifier}"
        end

        def base_path
          "#{object_path}/versions"
        end

        alias open_new_version_path base_path

        def close_version_path
          "#{base_path}/current/close"
        end
      end
    end
  end
end
