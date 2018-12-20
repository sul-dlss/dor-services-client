# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Objects do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com')
  end
  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  describe '#register' do
    let(:params) { { foo: 'bar' } }
    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects')
        .with(
          body: '{"foo":"bar"}',
          headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
        )
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { '{"pid":"druid:123"}' }

      it 'posts params as json' do
        expect(client.register(params: params)[:pid]).to eq 'druid:123'
      end
    end

    context 'when API request fails' do
      let(:status) { [409, 'object already exists'] }
      let(:body) { nil }

      it 'raises an error' do
        expect { client.register(params: params) }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                                                  'object already exists: 409 ()')
      end
    end
  end

  describe '#publish' do
    let(:pid) { 'druid:1234' }
    subject(:request) { client.publish(object: pid) }
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

  describe '#current_version' do
    let(:pid) { 'druid:1234' }
    subject(:request) { client.current_version(object: pid) }
    before do
      stub_request(:get, 'https://dor-services.example.com/v1/sdr/objects/druid:1234/current_version')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { '<currentVersion>2</currentVersion>' }

      it 'returns true' do
        expect(request).to eq 2
      end
    end

    context 'when API request responds with bad xml' do
      let(:status) { 200 }
      let(:body) { '<foo><bar>' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::MalformedResponse,
                                          'Unable to parse XML from current_version API call: <foo><bar>')
      end
    end

    context 'when API request fails' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          'internal server error: 500 (broken) for druid:1234')
      end
    end
  end
end
