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

    describe '.retrieve_file' do
      it 'calls #retrieve_file on a new instance' do
        expect(described_class.instance.files).to receive(:retrieve)
        described_class.retrieve_file(object: 'druid:123', filename: 'M1090_S15_B01_F04_0073.jp2')
      end
    end

    describe '.list_files' do
      it 'calls #list_files on a new instance' do
        expect(described_class.instance.files).to receive(:list)
        described_class.list_files(object: 'druid:123')
      end
    end
  end
end
