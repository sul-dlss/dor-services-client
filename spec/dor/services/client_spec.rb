# frozen_string_literal: true

RSpec.describe Dor::Services::Client do
  it 'has a version number' do
    expect(Dor::Services::Client::VERSION).not_to be nil
  end

  subject(:client) { described_class.instance }

  context 'once configured' do
    before do
      described_class.configure(url: 'https://dor-services.example.com')
    end

    describe '.register' do
      let(:params) { { foo: 'bar' } }

      it 'calls #register on a new instance' do
        expect(described_class.instance.objects).to receive(:register)
        described_class.register(params: params)
      end
    end

    describe '.notify_goobi' do
      let(:params) { { foo: 'bar' } }

      it 'calls #notify_goobi on a new instance' do
        expect(described_class.instance.objects).to receive(:notify_goobi)
        described_class.notify_goobi(params: params)
      end
    end

    describe '.retrieve_file' do
      it 'calls #retrieve on a the file' do
        expect(described_class.instance.files).to receive(:retrieve)
        described_class.retrieve_file(object: 'druid:123', filename: 'M1090_S15_B01_F04_0073.jp2')
      end
    end

    describe '.list_files' do
      it 'calls #list on the files' do
        expect(described_class.instance.files).to receive(:list)
        described_class.list_files(object: 'druid:123')
      end
    end

    describe '.preserved_content' do
      it 'calls #preserved_content on a the file' do
        expect(described_class.instance.files).to receive(:preserved_content)
        described_class.preserved_content(object: 'druid:123', filename: 'M1090_S15_B01_F04_0073.jp2', version: 2)
      end
    end

    describe '.initialize_workspace' do
      it 'calls #create on a new instance' do
        expect(described_class.instance.workspace).to receive(:create)
        described_class.initialize_workspace(object: 'druid:123', source: 'foo/bar/baz')
      end
    end

    describe '.create_release_tag' do
      it 'calls #create on a the release_tags' do
        expect(described_class.instance.release_tags).to receive(:create)
        described_class.create_release_tag(object: 'druid:123',
                                           release: true,
                                           to: 'searchworks',
                                           who: 'justin',
                                           what: 'foo')
      end
    end

    describe '.publish' do
      it 'calls #publish on a the object' do
        expect(described_class.instance.objects).to receive(:publish)
        described_class.publish(object: 'druid:123')
      end
    end

    describe '.current_version' do
      it 'calls #current_version on a the object' do
        expect(described_class.instance.objects).to receive(:current_version)
        described_class.current_version(object: 'druid:123')
      end
    end
  end

  describe '#configure' do
    subject(:client) { described_class.configure(url: 'https://dor-services.example.com') }

    it 'returns Client class' do
      expect(client).to eq Dor::Services::Client
    end
  end

  context 'when passed a username and password' do
    before do
      described_class.configure(url: 'https://dor-services.example.com',
                                username: username,
                                password: password)
    end

    let(:username) { 'foo' }
    let(:password) { 'bar' }

    it 'sets the Authorization header on the instance connection' do
      expect(described_class.instance.send(:connection).headers).to include(
        'Authorization' => 'Basic Zm9vOmJhcg=='
      )
    end
  end
end
