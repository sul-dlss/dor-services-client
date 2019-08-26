# frozen_string_literal: true

RSpec.describe Dor::Services::Client::ResponseErrorFormatter do
  let(:response) { double('http response', reason_phrase: 'Internal Server Error', status: 500, body: 'Something went badly') }

  subject(:formatter) { described_class.new(response: response) }

  describe '.format' do
    let(:mock_instance) { double('mock instance') }

    it 'calls #format on a new instance' do
      allow(mock_instance).to receive(:format)
      allow(described_class).to receive(:new).with(response: response).and_return(mock_instance)
      described_class.format(response: response)
      expect(described_class).to have_received(:new).once
      expect(mock_instance).to have_received(:format).once
    end
  end

  describe '#initialize' do
    it 'has a reason_phrase attribute' do
      expect(formatter.reason_phrase).to eq('Internal Server Error')
    end

    it 'has a status attribute' do
      expect(formatter.status).to eq(500)
    end

    it 'has a body attribute' do
      expect(formatter.body).to eq('Something went badly')
    end

    context 'with a blank body' do
      let(:response) { double('http response', reason_phrase: 'Internal Server Error', status: 500, body: '') }

      it 'sets a default body attribute' do
        expect(formatter.body).to eq(described_class::DEFAULT_BODY)
      end
    end
  end

  describe '#format' do
    it 'formats an error message from attributes in the instance' do
      expect(formatter.format).to eq('Internal Server Error: 500 (Something went badly)')
    end
  end
end
