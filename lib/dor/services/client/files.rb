# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls relating to files
      class Files < VersionedService
        # Get the contents from the workspace
        # @param [String] object the identifier for the object
        # @param [String] filename the name of the file to retrieve
        # @return [String] the file contents from the workspace
        def retrieve(object:, filename:)
          resp = connection.get do |req|
            req.url "#{api_version}/objects/#{object}/contents/#{filename}"
          end
          return unless resp.success?

          resp.body
        end

        # Get the preserved file contents
        # @param [String] object the identifier for the object
        # @param [String] filename the name of the file to retrieve
        # @param [Integer] version the version of the file to retrieve
        # @return [String] the file contents from the SDR
        def preserved_content(object:, filename:, version:)
          resp = connection.get do |req|
            req.url "#{api_version}/sdr/objects/#{object}/content/#{CGI.escape(filename)}?version=#{version}"
          end
          return unless resp.success?

          resp.body
        end

        # Get the list of files in the workspace
        # @param [String] object the identifier for the object
        # @return [Array<String>] the list of filenames in the workspace
        def list(object:)
          resp = connection.get do |req|
            req.url "#{api_version}/objects/#{object}/contents"
          end
          return [] unless resp.success?

          json = JSON.parse(resp.body)
          json['items'].map { |item| item['name'] }
        end
      end
    end
  end
end
