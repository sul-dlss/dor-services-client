# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls around workflows for an object.
      class ObjectWorkflows < VersionedService
        # @param object_identifier [String] the druid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Retrieves all workflows for the given object
        # @return [Dor::Services::Response::Workflows]
        def list
          resp = connection.get do |req|
            req.url "#{api_version}/objects/#{object_identifier}/workflows"
            req.headers['Accept'] = 'application/xml'
          end
          raise_exception_based_on_response!(resp) unless resp.success?

          Dor::Services::Response::Workflows.new(xml: Nokogiri::XML(resp.body))
        end

        private

        attr_reader :object_identifier
      end
    end
  end
end
