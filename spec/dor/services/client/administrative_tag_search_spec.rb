# frozen_string_literal: true

RSpec.describe Dor::Services::Client::AdministrativeTagSearch do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  describe '#search' do
    before do
      stub_request(:get, 'https://dor-services.example.com/v1/administrative_tags/search?q=foo')
        .to_return(status: status, body: body)
    end

    context 'when API request returns 200' do
      let(:status) { 200 }
      let(:body) { '["tag1","tag2"]' }

      it 'gets the status as a hash' do
        result = client.search(q: 'foo')
        expect(result).to eq body
      end
    end

    context 'when API request fails with 400' do
      let(:status) { [400, 'bad request'] }
      let(:body) { '{"errors":["error message here"]}' }

      it 'raises an error' do
        expect { client.search(q: 'foo') }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                                          "bad request: 400 (#{body})")
      end
    end
  end
end
