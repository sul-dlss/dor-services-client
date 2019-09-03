# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about a repository object
      class Object < VersionedService
        attr_reader :object_identifier

        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          raise ArgumentError, "The `object_identifier` parameter must be an identifier string: #{object_identifier.inspect}" unless object_identifier.is_a?(String)

          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        def sdr
          @sdr ||= SDR.new(connection: connection, version: api_version, object_identifier: object_identifier)
        end

        def metadata
          @metadata ||= Metadata.new(connection: connection, version: api_version, object_identifier: object_identifier)
        end

        def files
          @files ||= Files.new(connection: connection, version: api_version, object_identifier: object_identifier)
        end

        def workspace
          @workspace ||= Workspace.new(connection: connection, version: api_version, object_identifier: object_identifier)
        end

        def release_tags
          @release_tags ||= ReleaseTags.new(connection: connection, version: api_version, object_identifier: object_identifier)
        end

        def version
          @version ||= ObjectVersion.new(connection: connection, version: api_version, object_identifier: object_identifier)
        end

        # Publish a new object
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def publish
          resp = connection.post do |req|
            req.url "#{object_path}/publish"
          end
          return true if resp.success?

          raise_exception_based_on_response!(resp)
        end

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

        # Pull in metadata from Symphony and update descMetadata
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def refresh_metadata
          resp = connection.post do |req|
            req.url "#{object_path}/refresh_metadata"
          end
          return true if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Does a virtual-merge of the children into the parent
        # @param [Array<String>] child_druids the identifier of the children
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def add_constituents(child_druids:)
          resp =  connection.put object_path, constituent_ids: child_druids
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

        def object_path
          "#{api_version}/objects/#{object_identifier}"
        end

        def raise_exception_based_on_response!(response)
          raise (response.status == 404 ? NotFoundResponse : UnexpectedResponse),
                ResponseErrorFormatter.format(response: response)
        end
      end
    end
  end
end
