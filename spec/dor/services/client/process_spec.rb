# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Process do
  subject(:client) do
    described_class.new(connection: connection, version: 'v1', object_identifier: druid,
                        workflow_name: 'accessionWF', process: 'shelve')
  end

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123', enable_get_retries: false)
    stub_request(:put, 'https://dor-services.example.com/v1/objects/druid:mw971zk1113/workflows/accessionWF/processes/shelve')
      .with(
        headers: { 'Content-Type' => 'application/json' },
        body: body
      )
      .to_return(status: status)
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:status) { 204 }
  let(:druid) { 'druid:mw971zk1113' }

  describe '#update' do
    context 'when API request succeeds' do
      let(:body) do
        {
          status: 'completed',
          elapsed: 0
        }
      end

      it 'does not raise' do
        expect { client.update(status: 'completed') }.not_to raise_error
      end
    end

    context 'when API request succeeds with additional parameters' do
      let(:body) do
        {
          status: 'completed',
          elapsed: 5.5,
          lifecycle: 'publish',
          note: 'All good'
        }
      end

      it 'does not raise' do
        expect { client.update(status: 'completed', elapsed: 5.5, lifecycle: 'publish', note: 'All good') }.not_to raise_error
      end
    end

    context 'when API request returns 409' do
      let(:status) { [409, 'conflict'] }

      let(:body) do
        {
          status: 'completed',
          elapsed: 0,
          current_status: 'started'
        }
      end

      it 'raises a ConflictResponse exception' do
        expect { client.update(status: 'completed', current_status: 'started') }.to raise_error(Dor::Services::Client::ConflictResponse)
      end
    end
  end

  describe '#update_error' do
    let(:body) do
      {
        status: 'error',
        error_msg: 'Ooops',
        error_text: 'the backtrace'
      }
    end

    it 'does not raise' do
      expect { client.update_error(error_msg: 'Ooops', error_text: 'the backtrace') }.not_to raise_error
    end
  end
end
