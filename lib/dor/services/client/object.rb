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
          @sdr ||= SDR.new(parent_params)
        end

        def metadata
          @metadata ||= Metadata.new(parent_params)
        end

        def files
          @files ||= Files.new(parent_params)
        end

        def workspace
          @workspace ||= Workspace.new(parent_params)
        end

        def release_tags
          @release_tags ||= ReleaseTags.new(parent_params)
        end

        def version
          @version ||= ObjectVersion.new(parent_params)
        end

        def embargo
          @embargo ||= Embargo.new(parent_params)
        end

        # Retrieves the Cocina model
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] the returned model
        def find
          resp = connection.get do |req|
            req.url object_path
          end

          return Cocina::Models.build(JSON.parse(resp.body)) if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Get a list of the collections. (Similar to Valkyrie's find_inverse_references_by)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return [Array<Cocina::Models::DRO>]
        def collections
          Collections.new(parent_params).collections
        end

        # Publish an object (send to PURL)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @param [String] workflow ('accessionWF') which workflow to callback to.
        # @return [boolean] true on success
        def publish(workflow: nil)
          publish_path = "#{object_path}/publish"
          publish_path = "#{publish_path}?workflow=#{workflow}" if workflow
          resp = connection.post do |req|
            req.url publish_path
          end
          return resp.headers['Location'] if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Preserve an object (send to SDR)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [String] URL from Location response header if no errors
        def preserve
          resp = connection.post do |req|
            req.url "#{object_path}/preserve"
          end
          return resp.headers['Location'] if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Shelve an object (send to Stacks)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def shelve
          resp = connection.post do |req|
            req.url "#{object_path}/shelve"
          end
          return resp.headers['Location'] if resp.success?

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
