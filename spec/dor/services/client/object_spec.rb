# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Object do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com')
  end
  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  subject(:client) { described_class.new(connection: connection, version: 'v1', object: pid) }

  describe '#publish' do
    let(:pid) { 'druid:1234' }
    subject(:request) { client.publish }
    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/publish')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns true' do
        expect(request).to be true
      end
    end

    context 'when API request fails' do
      let(:status) { [409, 'conflict'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse, 'conflict: 409 ()')
      end
    end
  end

  describe '#notify_goobi' do
    let(:pid) { 'druid:1234' }
    subject(:request) { client.notify_goobi }
    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/notify_goobi')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns true' do
        expect(request).to be true
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse, 'unauthorized: 401 ()')
      end
    end
  end
end
