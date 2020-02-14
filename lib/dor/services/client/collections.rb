# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are queries about a particular object.
      # This attempts to parallel the Valkyrie QueryService interface
      # (e.g. https://github.com/samvera/valkyrie/blob/master/lib/valkyrie/persistence/memory/query_service.rb)
      class Collections < VersionedService
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Get a list of the collections. (Similar to Valkyrie's find_inverse_references_by)
        # @raise [UnexpectedResponse] if the request is unsuccessful.
        # @return [Array<Cocina::Models::DRO>]
        def collections
          resp = connection.get do |req|
            req.url "#{query_path}/collections"
          end

          return response_to_models(resp) if resp.success?

          raise_exception_based_on_response!(resp, object_identifier)
        end

        private

        def response_to_models(resp)
          JSON.parse(resp.body)['collections'].map { |data| Cocina::Models.build(data) }
        end

        def object_path
          "#{api_version}/objects/#{object_identifier}"
        end

        def query_path
          "#{object_path}/query"
        end

        attr_reader :object_identifier
      end
    end
  end
end
