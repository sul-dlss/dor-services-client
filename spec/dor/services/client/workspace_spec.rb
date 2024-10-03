# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Workspace do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:123' }

  describe '#create' do
    let(:path_to_workspace) { '/dor/workspace/123' }
    let(:source) { 'abd/cwef/vwef/content' }

    context 'when API request succeeds with source param' do
      subject(:request) { client.create(source: source) }

      before do
        stub_request(:post, "https://dor-services.example.com/v1/objects/druid:123/workspace?source=#{source}&metadata=false&content=false")
          .to_return(status: 201, body: { path: path_to_workspace }.to_json)
      end

      it 'posts params and returns directory' do
        expect(request).to eq path_to_workspace
      end
    end

    context 'when API request succeeds without source param' do
      subject(:request) { client.create }

      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/workspace?metadata=false&content=false')
          .to_return(status: 201, body: { path: path_to_workspace }.to_json)
      end

      it 'posts params and returns directory' do
        expect(request).to eq path_to_workspace
      end
    end

    context 'when API request succeeds without source param and with content param' do
      subject(:request) { client.create(content: true) }

      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/workspace?metadata=false&content=true')
          .to_return(status: 201, body: { path: path_to_workspace }.to_json)
      end

      it 'posts params and returns directory' do
        expect(request).to eq path_to_workspace
      end
    end

    context 'when API request succeeds without source param and with metadata param' do
      subject(:request) { client.create(metadata: true) }

      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/workspace?metadata=true&content=false')
          .to_return(status: 201, body: { path: path_to_workspace }.to_json)
      end

      it 'posts params and returns directory' do
        expect(request).to eq path_to_workspace
      end
    end

    context 'when API request succeeds without source param and with content and metadata params' do
      subject(:request) { client.create(content: true, metadata: true) }

      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/workspace?metadata=true&content=true')
          .to_return(status: 201, body: { path: path_to_workspace }.to_json)
      end

      it 'posts params and returns directory' do
        expect(request).to eq path_to_workspace
      end
    end

    context 'when API request fails' do
      subject(:request) { client.create(source: source) }

      before do
        stub_request(:post, "https://dor-services.example.com/v1/objects/druid:123/workspace?source=#{source}&metadata=false&content=false")
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "something is amiss: 500 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:123")
      end
    end
  end

  describe '#reset' do
    subject(:request) { client.reset(workflow: workflow, lane_id: lane_id) }

    let(:workflow) { nil }
    let(:lane_id) { nil }

    context 'when API request succeeds' do
      let(:workflow) { 'accessionWF' }
      let(:lane_id) { 'low' }

      before do
        stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:123/workspace?workflow=accessionWF&lane-id=low')
          .to_return(status: 201)
      end

      it 'raises no errors' do
        expect(request).to be_nil
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:123/workspace')
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "something is amiss: 500 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:123")
      end
    end
  end
end
