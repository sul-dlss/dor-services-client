# frozen_string_literal: true

RSpec.describe Dor::Services::Client::UserVersion do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123', enable_get_retries: false)
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:bc123df4567' }

  describe '#inventory' do
    subject(:request) { client.inventory }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/user_versions')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) do
        <<~JSON
          {"user_versions":[
            {"version":1,"userVersion":1},
            {"version":3,"userVersion":2}
          ]}
        JSON
      end

      it 'returns the list of versions' do
        expect(request).to eq [
          described_class::Version.new(version: 1, userVersion: 1),
          described_class::Version.new(version: 3, userVersion: 2)
        ]
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }
      let(:body) { '' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnauthorizedResponse)
      end
    end

    context 'when connection fails' do
      before do
        allow_any_instance_of(Faraday::Adapter::NetHttp).to receive(:call).and_raise(Faraday::ConnectionFailed.new('end of file reached')) # rubocop:disable RSpec/AnyInstance
      end

      let(:status) { 555 }
      let(:body) { '' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::ConnectionFailed, 'unable to reach dor-services-app: end of file reached')
      end
    end
  end

  describe '#find' do
    subject(:model) { client.find(2) }

    let(:cocina) { build(:dro, id: 'druid:bc123df4567') }

    let(:status) { 200 }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/user_versions/2')
        .to_return(status: status,
                   body: cocina.to_json,
                   headers: {
                     'Last-Modified' => 'Wed, 03 Mar 2021 18:58:00 GMT',
                     'X-Created-At' => 'Wed, 01 Jan 2021 12:58:00 GMT',
                     'X-Served-By' => 'Awesome webserver',
                     'ETag' => 'W/"d41d8cd98f00b204e9800998ecf8427e"'
                   })
    end

    context 'when API request succeeds with DRO' do
      it 'returns the cocina model' do
        expect(model.externalIdentifier).to eq 'druid:bc123df4567'
        expect(model.lock).to eq('W/"d41d8cd98f00b204e9800998ecf8427e"')
        expect(model.created.to_s).to eq('2021-01-01T12:58:00+00:00')
        expect(model.modified.to_s).to eq('2021-03-03T18:58:00+00:00')
      end
    end
  end
end
