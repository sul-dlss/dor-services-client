# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Objects do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com')
  end
  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  subject(:client) { described_class.new(connection: connection) }

  describe '#register' do
    let(:params) { { foo: 'bar' } }

    context 'when API request succeeds' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects')
          .with(
            body: '{"foo":"bar"}',
            headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
          )
          .to_return(status: 200, body: '{"pid":"druid:123"}', headers: {})
      end

      it 'posts params as json' do
        expect(client.register(params: params)[:pid]).to eq 'druid:123'
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects')
          .with(
            body: '{"foo":"bar"}',
            headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
          )
          .to_return(status: [409, 'object already exists'])
      end

      it 'raises an error' do
        expect { client.register(params: params) }.to raise_error('object already exists: 409 ()')
      end
    end
  end

  describe '#publish' do
    let(:pid) { 'druid:1234' }
    subject(:request) { client.publish(object: pid) }

    context 'when API request succeeds' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/publish')
          .to_return(status: 200)
      end

      it 'returns true' do
        expect(request).to be true
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/publish')
          .to_return(status: [409, 'conflict'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::Error, 'conflict: 409 ()')
      end
    end
  end
end
