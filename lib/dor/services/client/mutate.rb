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

          raise_exception_based_on_response!(resp) unless resp.success?

          Cocina::Models.build(JSON.parse(resp.body))
        end

        # Pull in metadata from Symphony and updates descriptive metadata
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @return [boolean] true on success
        def refresh_metadata
          resp = connection.post do |req|
            req.url "#{object_path}/refresh_metadata"
          end

          raise_exception_based_on_response!(resp) unless resp.success?

          true
        end

        # Destroys an object
        # @return [Boolean] true if successful
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        def destroy
          resp = connection.delete do |req|
            req.url object_path
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
