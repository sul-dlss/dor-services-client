# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls relating to files
      class Files < VersionedService
        def retrieve(object:, filename:)
          resp = connection.get do |req|
            req.url "#{version}/objects/#{object}/contents/#{filename}"
          end
          return unless resp.success?

          resp.body
        end

        def list(object:)
          resp = connection.get do |req|
            req.url "#{version}/objects/#{object}/contents"
          end
          return [] unless resp.success?

          json = JSON.parse(resp.body)
          json['items'].map { |item| item['name'] }
        end
      end
    end
  end
end
