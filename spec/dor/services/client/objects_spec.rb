# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Objects do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
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
                                                                  "object already exists: 409 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end
  end
end
