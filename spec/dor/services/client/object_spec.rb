# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Object do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:1234' }

  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  describe '#object_identifier' do
    it 'returns the injected pid' do
      expect(client.object_identifier).to eq pid
    end
  end

  describe '#files' do
    it 'returns an instance of Client::Files' do
      expect(client.files).to be_instance_of Dor::Services::Client::Files
    end
  end

  describe '#release_tags' do
    it 'returns an instance of Client::ReleaseTags' do
      expect(client.release_tags).to be_instance_of Dor::Services::Client::ReleaseTags
    end
  end

  describe '#sdr' do
    it 'returns an instance of Client::SDR' do
      expect(client.sdr).to be_instance_of Dor::Services::Client::SDR
    end
  end

  describe '#metadata' do
    it 'returns an instance of Client::Metadata' do
      expect(client.metadata).to be_instance_of Dor::Services::Client::Metadata
    end
  end

  describe '#workflow' do
    it 'returns an instance of Client::Workflow' do
      expect(client.workflow).to be_instance_of Dor::Services::Client::Workflow
    end
  end

  describe '#workspace' do
    it 'returns an instance of Client::Workspace' do
      expect(client.workspace).to be_instance_of Dor::Services::Client::Workspace
    end
  end

  describe '#version' do
    it 'returns an instance of Client::ObjectVersion' do
      expect(client.version).to be_instance_of Dor::Services::Client::ObjectVersion
    end
  end

  describe '#publish' do
    subject(:request) { client.publish }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/publish')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns true' do
        expect(request).to be true
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse, 'not found: 404 ()')
      end
    end

    context 'when API request fails' do
      let(:status) { [409, 'conflict'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse, 'conflict: 409 ()')
      end
    end
  end

  describe '#update_marc_record' do
    subject(:request) { client.update_marc_record }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/update_marc_record')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 201 }

      it 'returns true' do
        expect(request).to be true
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse, 'not found: 404 ()')
      end
    end

    context 'when API request fails' do
      let(:status) { [409, 'conflict'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse, 'conflict: 409 ()')
      end
    end
  end

  describe '#refresh_metadata' do
    subject(:request) { client.refresh_metadata }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/refresh_metadata')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns true' do
        expect(request).to be true
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse, 'not found: 404 ()')
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse, 'unauthorized: 401 ()')
      end
    end
  end

  describe '#notify_goobi' do
    subject(:request) { client.notify_goobi }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/notify_goobi')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns true' do
        expect(request).to be true
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse, 'not found: 404 ()')
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse, 'unauthorized: 401 ()')
      end
    end
  end

  describe '#current_version' do
    let(:object_version) { instance_double(Dor::Services::Client::ObjectVersion) }

    before do
      allow(client).to receive(:version).and_return(object_version)
      allow(object_version).to receive(:current).and_return(3)
      allow(Deprecation).to receive(:warn)
    end

    it 'delegates' do
      expect(client.current_version).to eq(3)
      expect(object_version).to have_received(:current)
      expect(Deprecation).to have_received(:warn)
    end
  end

  describe '#open_new_version' do
    let(:object_version) { instance_double(Dor::Services::Client::ObjectVersion) }

    let(:params) { { foo: 'bar' } }

    before do
      allow(client).to receive(:version).and_return(object_version)
      allow(object_version).to receive(:open)
      allow(Deprecation).to receive(:warn)
    end

    it 'delegates' do
      client.open_new_version params
      expect(object_version).to have_received(:open).with(params)
      expect(Deprecation).to have_received(:warn)
    end
  end

  describe '#close_version' do
    let(:object_version) { instance_double(Dor::Services::Client::ObjectVersion) }

    let(:params) { { foo: 'bar' } }

    before do
      allow(client).to receive(:version).and_return(object_version)
      allow(object_version).to receive(:close)
      allow(Deprecation).to receive(:warn)
    end

    it 'delegates' do
      client.close_version params
      expect(object_version).to have_received(:close).with(params)
      expect(Deprecation).to have_received(:warn)
    end
  end
end
