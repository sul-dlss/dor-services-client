# frozen_string_literal: true

module Dor
  module Services
    module Response
      # The response from asking the server about all workflows for an item
      class Workflows
        attr_reader :xml

        # @param [Nokogiri::XML] xml Nokogiri XML document showing all workflows
        def initialize(xml:)
          @xml = xml
        end

        def pid
          xml.at_xpath('/workflows/@objectId').text
        end

        def workflows
          @workflows ||= xml.xpath('/workflows/workflow').map do |node|
            Workflow.new(xml: node.to_xml)
          end
        end

        # @return [Array<String>] returns a list of errors for any process for the specified version
        def errors_for(version:)
          xml.xpath("//workflow/process[@version='#{version}' and @status='error']/@errorMessage").map(&:text)
        end
      end
    end
  end
end
