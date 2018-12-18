# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls relating to files
      class Files
        def initialize(connection:)
          @connection = connection
        end

        def retrieve(object:, filename:)
          resp = connection.get do |req|
            req.url "v1/objects/#{object}/contents/#{filename}"
          end
          return unless resp.success?

          resp.body
        end

        def list(object:)
          resp = connection.get do |req|
            req.url "v1/objects/#{object}/contents"
          end
          return [] unless resp.success?

          json = JSON.parse(resp.body)
          json['items'].map { |item| item['name'] }
        end

        private

        attr_reader :connection
      end
    end
  end
end
