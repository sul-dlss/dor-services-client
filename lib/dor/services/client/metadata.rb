# frozen_string_literal: tru

module Dor
  module Services
    class Client
      # API calls that are about retrieving metadata
      class Metadata < VersionedService
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # @return [String] The Dublin Core XML representation of the object
        def dublin_core
          resp = connection.get do |req|
            req.url "#{base_path}/dublin_core"
          end
          return resp.body if resp.success?
          return if resp.status == 404

          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body}) for #{object_identifier}"
        end

        # @return [String] The descriptive metadata XML representation of the object
        def descriptive
          resp = connection.get do |req|
            req.url "#{base_path}/descriptive"
          end
          return resp.body if resp.success?
          return if resp.status == 404

          raise UnexpectedResponse, "#{resp.reason_phrase}: #{resp.status} (#{resp.body}) for #{object_identifier}"
        end

        private

        attr_reader :object_identifier

        def base_path
          "#{api_version}/objects/#{object_identifier}/metadata"
        end
      end
    end
  end
end
