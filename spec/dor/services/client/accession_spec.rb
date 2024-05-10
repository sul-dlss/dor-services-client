# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Accession do
  subject(:client) do
    described_class.new(connection: connection,
                        object_identifier: 'druid:1234',
                        version: 'v1')
  end

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:headers) { { 'Authorization' => 'Bearer 123', 'Content-Type' => 'application/json' } }
  let(:body) { '' }

  describe '#start' do
    context 'with no params' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/accession')
          .with(body: body, headers: headers).to_return(status: status)
      end

      context 'when API request succeeds' do
        let(:status) { 201 }

        it 'returns true' do
          expect(client.start).to be true
        end
      end

      context 'when API request fails' do
        let(:status) { [500, 'internal server error'] }

        it 'raises an error' do
          expect { client.start }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                                 "internal server error: 500 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
        end
      end
    end

    context 'with params' do
      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:1234/accession?workflow=accessionWF&opening_user_name=dude')
          .with(body: body, headers: headers).to_return(status: status)
      end

      context 'when API request succeeds' do
        let(:status) { 201 }
        let(:params) { { opening_user_name: 'dude', workflow: 'accessionWF' } }

        it 'returns true' do
          expect(client.start(params)).to be true
        end

        context 'with context' do
          let(:body) { '{"context":{"requireOCR":true}}' }
          let(:params) { { opening_user_name: 'dude', workflow: 'accessionWF', context: { 'requireOCR' => true } } }

          it 'returns true' do
            expect(client.start(params)).to be true
          end
        end
      end
    end
  end
end
