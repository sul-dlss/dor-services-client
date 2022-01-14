# frozen_string_literal: true

RSpec.describe Dor::Services::Client::VirtualObjects do
  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  describe '#create' do
    let(:params) do
      {
        virtual_objects: virtual_objects
      }
    end
    let(:virtual_objects) do
      [
        {
          parent_id: 'druid:1',
          child_ids: [
            'druid:2',
            'druid:3'
          ]
        }
      ]
    end

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/virtual_objects')
        .with(
          body: params,
          headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
        )
        .to_return(status: status, body: body, headers: { 'Location' => 'https://dor-services.example.com/v1/background_job_results/123' })
    end

    context 'when API request succeeds' do
      let(:status) { 201 }
      let(:body) { '' }

      it 'posts params and returns a location header' do
        expect(client.create(virtual_objects: virtual_objects)).to eq('https://dor-services.example.com/v1/background_job_results/123')
      end
    end

    context 'when API request fails with 400' do
      let(:status) { [400, 'bad request'] }
      let(:body) { '{"errors":["error message here"]}' }

      it 'raises an error' do
        expect { client.create(virtual_objects: virtual_objects) }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                                                                  "bad request: 400 (#{body})")
      end
    end
  end
end
