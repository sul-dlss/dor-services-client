# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Objects do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  describe '#register' do
    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects')
        .with(
          body: expected_request,
          headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
        )
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds with a cocina model' do
      let(:status) { 200 }
      let(:expected_request) { model.to_json }
      let(:body) { Cocina::Models::DRO.new(model.to_h.merge(externalIdentifier: 'druid:bc222dfg3333')).to_json }
      let(:model) { Cocina::Models::RequestDRO.new(properties) }
      let(:item_type) { Cocina::Models::Vocab.object }

      let(:properties) do
        {
          type: item_type,
          label: 'My object',
          version: 3,
          description: {
            title: []
          }
        }
      end

      it 'posts params as json' do
        expect(client.register(params: model)).to be_kind_of Cocina::Models::DRO
      end
    end

    context 'when API request succeeds with a hash' do
      before do
        allow(Deprecation).to receive(:warn)
      end
      let(:params) { { foo: 'bar' } }
      let(:expected_request) { '{"foo":"bar"}' }
      let(:status) { 200 }
      let(:body) { '{"pid":"druid:123"}' }

      it 'posts params as json' do
        expect(client.register(params: params)[:pid]).to eq 'druid:123'
      end
    end

    context 'when API request fails' do
      before do
        allow(Deprecation).to receive(:warn)
      end
      let(:params) { { foo: 'bar' } }
      let(:expected_request) { '{"foo":"bar"}' }
      let(:status) { [409, 'object already exists'] }
      let(:body) { nil }

      it 'raises an error' do
        expect { client.register(params: params) }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                                                  "object already exists: 409 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end
  end
end
