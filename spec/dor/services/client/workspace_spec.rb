# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Workspace do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:123' }

  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  describe '#create' do
    subject(:request) { client.create(source: 'abd/cwef/vwef/content') }

    context 'when API request succeeds' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/workspace?source=abd/cwef/vwef/content')
          .to_return(status: 200)
      end

      it 'posts params' do
        expect(request).to be nil
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/workspace?source=abd/cwef/vwef/content')
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "something is amiss: 500 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:123")
      end
    end
  end

  describe '#cleanup' do
    subject(:request) { client.cleanup }

    context 'when API request succeeds' do
      before do
        stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:123/workspace')
          .to_return(status: 200)
      end

      it 'raises no errors' do
        expect(request).to be nil
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

  describe '#reset' do
    subject(:request) { client.reset }

    context 'when API request succeeds' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/workspace/reset')
          .to_return(status: 200)
      end

      it 'raises no errors' do
        expect(request).to be nil
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:123/workspace/reset')
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "something is amiss: 500 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:123")
      end
    end
  end
end
