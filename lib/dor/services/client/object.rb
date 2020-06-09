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

        def metadata
          @metadata ||= Metadata.new(**parent_params)
        end

        def events
          @events ||= Events.new(**parent_params)
        end

        def workspace
          @workspace ||= Workspace.new(**parent_params)
        end

        def release_tags
          @release_tags ||= ReleaseTags.new(**parent_params)
        end

        def administrative_tags
          @administrative_tags ||= AdministrativeTags.new(**parent_params)
        end

        def version
          @version ||= ObjectVersion.new(**parent_params)
        end

        def embargo
          @embargo ||= Embargo.new(**parent_params)
        end

        def accession(params = {})
          @accession ||= Accession.new(**parent_params.merge(params))
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

        # Updates the object
        # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection,Cocina::Models::RequestAPO] params model object
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] the returned model
        def update(params:)
          resp = connection.patch do |req|
            req.url object_path
            req.headers['Content-Type'] = 'application/json'
            # asking the service to return JSON (else it'll be plain text)
            req.headers['Accept'] = 'application/json'
            req.body = params.to_json
          end

          return Cocina::Models.build(JSON.parse(resp.body)) if resp.success?

          raise_exception_based_on_response!(resp)
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

        # Publish an object (send to PURL)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @param [String] workflow ('accessionWF') which workflow to callback to.
        # @param [String] lane_id for prioritization (default or low)
        # @return [boolean] true on success
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

        # Preserve an object (send to SDR)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @param [String] lane_id for prioritization (default or low)
        # @return [String] URL from Location response header if no errors
        def preserve(lane_id: nil)
          query_string = lane_id ? "?lane-id=#{lane_id}" : ''
          resp = connection.post do |req|
            req.url "#{object_path}/preserve#{query_string}"
          end
          return resp.headers['Location'] if resp.success?

          raise_exception_based_on_response!(resp)
        end

        # Shelve an object (send to Stacks)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @param [String] lane_id for prioritization (default or low)
        # @return [boolean] true on success
        def shelve(lane_id: nil)
          query_string = lane_id ? "?lane-id=#{lane_id}" : ''
          resp = connection.post do |req|
            req.url "#{object_path}/shelve#{query_string}"
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
      end
    end
  end
end
