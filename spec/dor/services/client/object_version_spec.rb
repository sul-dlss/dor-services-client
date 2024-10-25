# frozen_string_literal: true

RSpec.describe Dor::Services::Client::ObjectVersion do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: druid) }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123', enable_get_retries: false)
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:druid) { 'druid:bc123df4567' }

  describe '#find' do
    subject(:model) { client.find(2) }

    let(:cocina) { build(:dro, id: druid) }

    let(:status) { 200 }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/2')
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

  describe '#current_version' do
    subject(:request) { client.current }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current')
        .to_return(status: status, body: body)
    end

    let(:status) { [0, 'overwritten below when necessary'] }
    let(:body) { 'overwritten below when necessary' }

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { '2' }

      it 'returns the value' do
        expect(request).to eq '2'
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
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "unauthorized: 401 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end

    context 'when connection fails' do
      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current')
          .to_raise(Faraday::ConnectionFailed.new('end of file reached'))
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::ConnectionFailed, 'unable to reach dor-services-app: end of file reached')
      end
    end

    context 'when retriable error' do
      let(:logger) { instance_double(Logger, info: nil) }

      before do
        Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123', logger: logger)

        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current')
          .to_return(status: 503, body: '')
          .then.to_return(status: 200, body: '2')
      end

      it 'logs retries' do
        expect(request).to eq '2'
        expect(logger).to have_received(:info)
          .with('Retry 1 for https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current due to Faraday::RetriableResponse ()')
      end
    end
  end

  describe '#discard' do
    subject(:request) { client.discard }

    let(:status) { [209, 'no content'] }

    before do
      stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      it 'does not raise' do
        expect { request }.not_to raise_error
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "unauthorized: 401 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end

    context 'when connection fails' do
      before do
        stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current')
          .to_raise(Faraday::ConnectionFailed.new('end of file reached'))
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::ConnectionFailed, 'unable to reach dor-services-app: end of file reached')
      end
    end
  end

  describe '#inventory' do
    subject(:request) { client.inventory }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) do
        <<~JSON
          {"versions":[
            {"versionId":1,"message":"Initial version","cocina":true},
            {"versionId":2,"message":"Updated","cocina":false}
          ]}
        JSON
      end

      it 'returns the list of versions' do
        expect(request).to eq [
          described_class::Version.new(versionId: 1, message: 'Initial version', cocina: true),
          described_class::Version.new(versionId: 2, message: 'Updated', cocina: false)
        ]
        expect(request.first.version).to eq 1
        expect(request.first.cocina?).to be true
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
        allow_any_instance_of(Faraday::Adapter::NetHttp).to receive(:call).and_raise(Faraday::ConnectionFailed.new('end of file reached'))
      end

      let(:status) { 555 }
      let(:body) { '' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::ConnectionFailed, 'unable to reach dor-services-app: end of file reached')
      end
    end
  end

  describe '#open_new_version' do
    subject(:request) { client.open(**params) }

    let(:params) { {} }

    let(:created) { DateTime.parse('Wed, 01 Jan 2021 12:58:00 GMT') }

    let(:modified) { DateTime.parse('Wed, 03 Mar 2021 18:58:00 GMT') }

    let(:lock) { 'W/"d41d8cd98f00b204e9800998ecf8427e"' }

    let(:dro) do
      build(:dro, id: 'druid:bc123df4567')
    end

    let(:dro_with_metadata) do
      Cocina::Models.with_metadata(dro, lock, created: created, modified: modified)
    end

    let(:headers) do
      {
        'Last-Modified' => 'Wed, 03 Mar 2021 18:58:00 GMT',
        'X-Created-At' => 'Wed, 01 Jan 2021 12:58:00 GMT',
        'ETag' => 'W/"d41d8cd98f00b204e9800998ecf8427e"'
      }
    end

    let(:body) { dro.to_json }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: status, body: body,
                   headers: headers)
    end

    context 'with additional params' do
      let(:status) { 200 }
      let(:params) { { foo: 'bar' } }

      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions?foo=bar')
          .with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: status, body: body, headers: headers)
      end

      it 'returns cocina model with metadata' do
        expect(request).to eq dro_with_metadata
      end
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns cocina model with metadata' do
        expect(request).to eq dro_with_metadata
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
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an UnexpectedResponse error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          'internal server error: 500 (broken)')
      end
    end
  end

  describe '#close_version' do
    subject(:request) { client.close(**params) }

    let(:params) { {} }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current/close')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: status, body: body)
    end

    context 'with additional params' do
      let(:status) { 200 }
      let(:body) { 'version 2 closed' }
      let(:params) { { foo: 'bar' } }

      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current/close?foo=bar')
          .with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: status, body: body)
      end

      it 'returns confirmation message' do
        expect(request).to eq body
      end
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { 'version 2 closed' }

      it 'returns confirmation message' do
        expect(request).to eq body
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
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an UnexpectedResponse error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          'internal server error: 500 (broken)')
      end
    end
  end

  describe '#status' do
    subject(:request) { client.status }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/status')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      let(:body) do
        <<~JSON
          {"versionId":1,"open":true,"openable":false,"assembling":true,"accessioning":false,"closeable":true,"discardable":false}
        JSON
      end

      it 'returns the list of versions' do
        expect(request).to eq described_class::VersionStatus.new(versionId: 1, open: true, openable: false,
                                                                 assembling: true, accessioning: false, closeable: true,
                                                                 discardable: false)
        expect(request.version).to eq 1
        expect(request).to be_open
        expect(request).not_to be_openable
        expect(request).to be_assembling
        expect(request).not_to be_accessioning
        expect(request).not_to be_closed
        expect(request).to be_closeable
        expect(request).not_to be_discardable
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
        allow_any_instance_of(Faraday::Adapter::NetHttp).to receive(:call).and_raise(Faraday::ConnectionFailed.new('end of file reached'))
      end

      let(:status) { 555 }
      let(:body) { '' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::ConnectionFailed, 'unable to reach dor-services-app: end of file reached')
      end
    end
  end

  describe '#solr' do
    subject(:solr) { client.solr(2) }

    let(:expected_solr) do
      {
        'id' => druid,
        'current_version_isi' => 1,
        'obj_label_tesim' => 'Test DRO',
        'modified_latest_dttsi' => '2024-07-03T12:32:16Z',
        'created_at_dttsi' => '2024-07-03T12:32:16Z',
        'is_governed_by_ssim' => 'info:fedora/druid:hy787xj5878',
        'objectType_ssim' => ['item']
      }
    end

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/2/solr')
        .to_return(status: 200,
                   body: expected_solr.to_json)
    end

    context 'when API request succeeds' do
      it 'returns the solr document' do
        expect(solr).to eq expected_solr
      end
    end
  end
end
