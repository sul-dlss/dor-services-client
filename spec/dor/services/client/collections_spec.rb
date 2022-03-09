# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Collections do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:123' }

  describe '#collections' do
    subject(:collections) { client.collections }

    context 'when API request succeeds' do
      let(:json) do
        <<~JSON
          {
            "collections":[{
              "externalIdentifier":"druid:bc123df4567",
              "type":"#{Cocina::Models::ObjectType.collection}",
              "label":"my collection",
              "version":1,
              "description":{
                "purl":"https://purl.stanford.edu/bc123df4567",
                "title": [
                  { "value": "hey!", "type": "primary" }
                ]
              },
              "access": {}
            }]
          }
        JSON
      end

      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:123/query/collections')
          .to_return(status: 200, body: json)
      end

      it 'returns collections' do
        expect(collections.first.externalIdentifier).to eq 'druid:bc123df4567'
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:123/query/collections')
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { collections }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                              "something is amiss: 500 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:123")
      end
    end
  end
end
