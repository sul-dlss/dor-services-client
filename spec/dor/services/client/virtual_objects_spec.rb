# frozen_string_literal: true

RSpec.describe Dor::Services::Client::VirtualObjects do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  describe '#create' do
    let(:params) do
      {
        virtual_objects: [
          {
            parent_id: 'druid:1',
            child_ids: [
              'druid:2',
              'druid:3'
            ]
          }
        ]
      }
    end

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/virtual_objects')
        .with(
          body: params,
          headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
        )
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 204 }
      let(:body) { '' }

      it 'posts params and returns nil' do
        expect(client.create(params: params)).to be_nil
      end
    end

    context 'when API request fails with 422' do
      let(:status) { [422, 'unprocessable entity'] }
      let(:body) { '{"errors":["error message here"]}' }

      it 'raises an error' do
        expect { client.create(params: params) }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                                                "unprocessable entity: 422 (#{body})")
      end
    end
  end
end
