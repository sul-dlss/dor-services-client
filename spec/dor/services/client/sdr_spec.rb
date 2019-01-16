# frozen_string_literal: true

RSpec.describe Dor::Services::Client::SDR do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:1234' }

  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  describe '#current_version' do
    subject(:request) { client.current_version }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/sdr/objects/druid:1234/current_version')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { '<currentVersion>2</currentVersion>' }

      it 'returns true' do
        expect(request).to eq 2
      end
    end

    context 'when API request responds with bad xml' do
      let(:status) { 200 }
      let(:body) { '<foo><bar>' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::MalformedResponse,
                                          'Unable to parse XML from current_version API call: <foo><bar>')
      end
    end

    context 'when API request fails' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          'internal server error: 500 (broken) for druid:1234')
      end
    end
  end
end
