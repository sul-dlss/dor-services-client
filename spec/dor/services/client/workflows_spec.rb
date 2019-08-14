# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Workflows do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  describe '#initial' do
    before do
      stub_request(:get, 'https://dor-services.example.com/v1/workflows/accessionWF/initial')
        .to_return(status: status, body: body)
      allow(Deprecation).to receive(:warn)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { '<workflow></workflow>' }

      it 'gets the result' do
        expect(client.initial(name: 'accessionWF')).to eq body
        expect(Deprecation).to have_received(:warn)
      end
    end

    context 'when API request fails' do
      let(:status) { [404, 'not found'] }
      let(:body) { nil }

      it 'raises an error' do
        expect { client.initial(name: 'accessionWF') }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                                                      'not found: 404 ()')
        expect(Deprecation).to have_received(:warn)
      end
    end
  end
end
