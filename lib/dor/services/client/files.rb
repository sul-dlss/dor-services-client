# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls relating to files
      class Files < VersionedService
        extend Deprecation
        self.deprecation_horizon = 'dor-services-client version 4.0'

        # @param object_identifier [String] the pid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Get the contents from the workspace
        # @param [String] filename the name of the file to retrieve
        # @return [String] the file contents from the workspace
        def retrieve(filename:)
          resp = connection.get do |req|
            req.url "#{api_version}/objects/#{object_identifier}/contents/#{filename}"
          end
          return unless resp.success?

          resp.body
        end

        # Get the preserved file contents
        # @param [String] filename the name of the file to retrieve
        # @param [Integer] version the version of the file to retrieve
        # @return [String] the file contents from the SDR
        def preserved_content(filename:, version:)
          resp = connection.get do |req|
            req.url "#{api_version}/sdr/objects/#{object_identifier}/content/#{CGI.escape(filename)}?version=#{version}"
          end
          return unless resp.success?

          resp.body
        end
        deprecation_deprecate preserved_content: 'use preservation-client .content instead'

        # Get the list of files in the workspace
        # @return [Array<String>] the list of filenames in the workspace
        def list
          resp = connection.get do |req|
            req.url "#{api_version}/objects/#{object_identifier}/contents"
          end
          return [] unless resp.success?

          json = JSON.parse(resp.body)
          json['items'].map { |item| item['name'] }
        end

        private

        attr_reader :object_identifier
      end
    end
  end
end
