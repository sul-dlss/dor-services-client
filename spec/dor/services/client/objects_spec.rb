# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Objects do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  let(:model) { Cocina::Models::RequestDRO.new(properties) }
  let(:item_type) { Cocina::Models::Vocab.object }

  let(:properties) do
    {
      type: item_type,
      label: 'My object',
      version: 3,
      administrative: { hasAdminPolicy: 'druid:fv123df4567' },
      identification: { sourceId: 'sul:99999' }
    }
  end

  let(:expected_request) { model.to_json }

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
      let(:body) do
        Cocina::Models::DRO.new(model.to_h.merge(externalIdentifier: 'druid:bc123df4567',
                                                 access: {})).to_json
      end

      it 'posts params as json' do
        expect(client.register(params: model)).to be_kind_of Cocina::Models::DRO
      end
    end

    context 'when API request fails' do
      context 'when an unexpected response' do
        let(:status) { [409, 'object already exists'] }
        let(:body) { nil }

        it 'raises an error' do
          expect { client.register(params: model) }.to raise_error(Dor::Services::Client::ConflictResponse,
                                                                   "object already exists: 409 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
        end
      end

      context 'when an unauthorized response' do
        let(:status) { [401, 'unauthorized'] }
        let(:body) { nil }

        it 'raises an error' do
          expect { client.register(params: model) }.to raise_error(Dor::Services::Client::UnauthorizedResponse)
        end
      end
    end
  end
end
