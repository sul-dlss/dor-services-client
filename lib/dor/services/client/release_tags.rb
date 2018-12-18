# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls that are about a repository object
      class ReleaseTags
        def initialize(connection:)
          @connection = connection
        end

        attr_reader :connection

        # Creates a new release tag for the object
        # @param object [String] the pid for the object
        # @param release [Boolean]
        # @param what [String]
        # @param to [String]
        # @param who [String]
        # @return [Boolean] true if successful
        # rubocop:disable Metrics/MethodLength
        def create(object:, release:, what:, to:, who:)
          params = {
            to: to,
            who: who,
            what: what,
            release: release
          }
          resp = connection.post do |req|
            req.url "v1/objects/#{object}/release_tags"
            req.headers['Content-Type'] = 'application/json'
            req.body = params.to_json
          end
          raise Error, "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?

          true
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
