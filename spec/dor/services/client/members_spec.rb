# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Members do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:123' }

  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  describe '#members' do
    subject(:members) { client.members }

    context 'when API request succeeds' do
      let(:json) do
        <<~JSON
          {
            "members":[
              {
                "externalIdentifier":"druid:12343234",
                "type":"collection"
              },
              {
                "externalIdentifier":"druid:jg192kl9900",
                "type":"item"
              }
            ]
          }
        JSON
      end
      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:123/members')
          .to_return(status: 200, body: json)
      end

      it 'returns members' do
        expect(members.first.externalIdentifier).to eq 'druid:12343234'
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:123/members')
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { members }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "something is amiss: 500 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for druid:123")
      end
    end
  end
end
