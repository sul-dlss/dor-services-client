# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about starting accessioning on a repository object
      class Accession < VersionedService
        # @param connection [Faraday::Connection] an HTTP connection to dor-services-app
        # @param version [String] id for the version of the API call
        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Start accession on an object (start specified workflow, assemblyWF by default, and version if needed)
        # @param params [Hash<Symbol,String>] optional parameter hash
        # @option params [String] :description set description of version change - required
        # @option params [String] :opening_user_name add opening username to the event - optional
        # @option params [String] :workflow the workflow to start - defaults to 'assemblyWF'
        # @option params [Hash] :context the workflow context - optional
        # @return [Boolean] true on success
        # @raise [NotFoundResponse] when the response is a 404 (object not found)
        # @raise [UnexpectedResponse] when the response is not successful.
        def start(params = {})
          body = params[:context] ? { 'context' => params[:context] }.to_json : ''
          resp = connection.post do |req|
            req.url path
            req.params = params.except(:context)
            req.headers['Content-Type'] = 'application/json'
            req.body = body
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
