# frozen_string_literal: true

module Dor
  module Services
    class Client
      # API calls around milestones
      class Milestones < VersionedService
        # @param object_identifier [String] the druid for the object
        def initialize(connection:, version:, object_identifier:)
          super(connection: connection, version: version)
          @object_identifier = object_identifier
        end

        # Returns the Date for a requested milestone from workflow lifecycle
        #
        # @param [String] druid object id
        # @param [String] milestone_name the name of the milestone being queried for
        # @param [Number] version (nil) the version to query for
        # @param [Boolean] active_only (false) if true, return only lifecycle steps for versions that have all processes complete
        # @return [Time] when the milestone was achieved.  Returns nil if the milestone does not exist
        def date(milestone_name:, version: nil, active_only: false)
          filter_milestone(query_lifecycle(version: version, active_only: active_only), milestone_name)
        end

        # @return [Array<Hash>]
        def list
          doc = query_lifecycle(active_only: false)
          doc.xpath('//lifecycle/milestone').collect do |node|
            { milestone: node.text, at: Time.parse(node['date']), version: node['version'] }
          end
        end

        private

        attr_reader :object_identifier

        def filter_milestone(lifecycle_doc, milestone_name)
          milestone = lifecycle_doc.at_xpath("//lifecycle/milestone[text() = '#{milestone_name}']")
          return unless milestone

          Time.parse(milestone['date'])
        end

        # @param [String] druid object id
        # @param [Boolean] active_only (false) if true, return only lifecycle steps for versions that have all processes complete
        # @param [Number] version the version to query for
        # @return [Nokogiri::XML::Document]
        # @example An example lifecycle xml from the workflow service.
        #   <lifecycle objectId="druid:ct011cv6501">
        #     <milestone date="2010-04-27T11:34:17-0700">registered</milestone>
        #     <milestone date="2010-04-29T10:12:51-0700">inprocess</milestone>
        #     <milestone date="2010-06-15T16:08:58-0700">released</milestone>
        #   </lifecycle>
        #
        def query_lifecycle(active_only:, version: nil)
          resp = connection.get do |req|
            req.url "#{api_version}/objects/#{object_identifier}/lifecycles"
            req.headers['Accept'] = 'application/xml'
            req.params['version'] = version if version
            req.params['active-only'] = 'true' if active_only
          end
          raise_exception_based_on_response!(resp) unless resp.success?

          Nokogiri::XML(resp.body)
        end
      end
    end
  end
end
