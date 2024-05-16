# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about user versions
      class UserVersion < VersionedService
        Version = Struct.new(:version, :userVersion, keyword_init: true)

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
