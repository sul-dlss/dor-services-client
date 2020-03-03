# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about starting accessioning on a repository object
      class Accession < VersionedService
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Start accession on an object (start specified workflow, assemblyWF by default, and version if needed)
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        # @param [String] :significance set significance (major/minor/patch) of version change
        # @param [String] :description set description of version change
        # @param [String] :opening_user_name add opening username to the events datastream
        # @param [String] :workflow the workflow to start (defaults to 'assemblyWF')
        # @return [boolean] true on success
        def start(params = {})
          resp = connection.post do |req|
            req.url path
            req.params = params
          end
          return true if resp.success?

          raise_exception_based_on_response!(resp)
        end

        private

        attr_reader :object_identifier

        def path
          "#{api_version}/objects/#{object_identifier}/accession"
        end
      end
    end
  end
end
