# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Milestones do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: druid) }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123', enable_get_retries: false)
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:druid) { 'druid:gv054hp4128' }

  let(:ng_xml) { Nokogiri::XML(xml) }
  let(:xml) do
    '<?xml version="1.0" encoding="UTF-8"?><lifecycle objectId="druid:gv054hp4128"><milestone date="2012-01-26T21:06:54-0800" version="2">published</milestone></lifecycle>'
  end

  describe '#list' do
    subject(:milestones) { client.list }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:gv054hp4128/lifecycles')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { xml }

      it 'includes the version in with the milestones' do
        expect(milestones.first[:milestone]).to eq('published')
        expect(milestones.first[:version]).to eq('2')
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { milestones }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end
  end

  describe '#date' do
    subject(:date) { client.date(milestone_name: 'published', version: version) }

    let(:version) { nil }

    let(:status) { 200 }
    let(:body) { xml }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:gv054hp4128/lifecycles')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      it 'returns the date' do
        expect(date).to eq(Time.parse('2012-01-26T21:06:54-0800'))
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { date }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'with parameters' do
      let(:version) { '2' }

      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:gv054hp4128/lifecycles?version=2')
          .to_return(status: 200, body: xml)
      end

      it 'returns the date' do
        expect(date).to eq(Time.parse('2012-01-26T21:06:54-0800'))
      end
    end
  end
end
