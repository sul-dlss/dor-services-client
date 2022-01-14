# frozen_string_literal: true

RSpec.describe Dor::Services::Client::AsyncResult do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  describe '#wait_until_complete' do
    subject(:instance) { described_class.new(url: 'not evaluated') }

    let(:result1) { { status: 'pending', output: {} } }
    let(:result2) { { status: 'processing', output: {} } }
    let(:result3) { { status: 'complete', output: { errors: [{ 'druid:foo' => ['druid:bar'] }] } } }

    before do
      allow(Dor::Services::Client.background_job_results).to receive(:show).and_return(result1, result2, result3)
      allow_any_instance_of(described_class).to receive(:sleep)
    end

    context 'when it completes before the timeout' do
      it 'loops until the job status is complete and returns an output hash' do
        output = instance.wait_until_complete
        expect(Dor::Services::Client.background_job_results).to have_received(:show).exactly(3).times
        expect(output).to be false
        expect(instance.errors).to eq([{ 'druid:foo' => ['druid:bar'] }])
      end
    end

    context 'when it times out' do
      before do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
      end

      it 'sets an error' do
        output = instance.wait_until_complete
        expect(output).to be false
        expect(instance.errors).to eq(['Not complete after 180 seconds'])
      end
    end
  end
end
