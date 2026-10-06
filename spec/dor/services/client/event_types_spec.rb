# frozen_string_literal: true

RSpec.describe Dor::Services::Client::EventTypes do
  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  describe '#list' do
    subject(:response) { client.list }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/event_types')
        .with(headers: { 'Accept' => 'application/json' })
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { '["registration","version_close","version_open"]' }

      it 'returns the event types' do
        expect(response).to eq %w[registration version_close version_open]
      end
    end

    context 'when API request fails' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an error' do
        expect { response }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                           'internal server error: 500 (broken)')
      end
    end
  end
end
