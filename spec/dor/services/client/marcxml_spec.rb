# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Marcxml do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:barcode) { 'abc123' }
  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  describe '#catkey' do
    before do
      stub_request(:get, 'https://dor-services.example.com/v1/catalog/catkey')
        .with(
          query: { 'barcode' => barcode }
        )
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds and there is a body' do
      let(:status) { 200 }
      let(:body) { 'catkey:abc123' }

      it 'returns the catkey' do
        expect(client.catkey(barcode: barcode)).to eq(body)
      end
    end

    context 'when API request succeeds and there is no body (i.e., barcode is not found)' do
      let(:status) { 200 }
      let(:body) { '' }

      it 'raises a NotFoundResponse error' do
        expect { client.catkey(barcode: barcode) }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails with 500' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { '' }

      it 'raises an error' do
        expect { client.catkey(barcode: barcode) }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                                                  /internal server error: 500 /)
      end
    end
  end
end
