# frozen_string_literal: true

RSpec.describe Dor::Services::Client::BackgroundJobResults do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  subject(:client) { described_class.new(connection: connection, version: 'v1') }

  describe '#show' do
    before do
      stub_request(:get, 'https://dor-services.example.com/v1/background_job_results/123')
        .with(
          headers: { 'Accept' => 'application/json' }
        )
        .to_return(status: status, body: body)
    end

    context 'when API request returns 202' do
      let(:status) { 202 }
      let(:body) { '{"output":{},"status":"pending"}' }

      it 'gets the status as a hash' do
        result = client.show(job_id: 123)
        expect(result[:output]).to eq({})
        expect(result[:status]).to eq('pending')
      end
    end

    context 'when API request returns 200' do
      let(:status) { 200 }
      let(:body) { '{"output":{},"status":"complete"}' }

      it 'gets the status as a hash' do
        result = client.show(job_id: 123)
        expect(result[:output]).to eq({})
        expect(result[:status]).to eq('complete')
      end
    end

    context 'when API request returns 422' do
      let(:status) { 422 }
      let(:body) { '{"output":{"errors":["error one","error two"]},"status":"complete"}' }

      it 'gets the status as a hash' do
        result = client.show(job_id: 123)
        expect(result[:output][:errors]).to eq(['error one', 'error two'])
        expect(result[:status]).to eq('complete')
      end
    end

    context 'when API request fails with 400' do
      let(:status) { [400, 'bad request'] }
      let(:body) { '{"errors":["error message here"]}' }

      it 'raises an error' do
        expect { client.show(job_id: 123) }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                                           "bad request: 400 (#{body})")
      end
    end

    context 'when API request fails with 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '{"errors":["error message here"]}' }

      it 'raises an error' do
        expect { client.show(job_id: 123) }.to raise_error(Dor::Services::Client::NotFoundResponse,
                                                           "not found: 404 (#{body})")
      end
    end
  end
end
