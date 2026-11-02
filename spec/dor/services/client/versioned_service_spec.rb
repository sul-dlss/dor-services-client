# frozen_string_literal: true

RSpec.describe Dor::Services::Client::VersionedService do
  subject(:client) { subclass.new(connection: connection, version: 'v1') }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:subclass) do
    Class.new(described_class)
  end
  let(:connection) { Dor::Services::Client.instance.send(:connection) }

  describe '#async_result' do
    it 'creates an instance of AsyncResult' do
      expect(client.async_result(url: 'foobar')).to be_a(Dor::Services::Client::AsyncResult)
    end
  end

  describe '#raise_exception_based_on_response!' do
    subject(:raise_exception) { client.send(:raise_exception_based_on_response!, response) }

    let(:response) do
      instance_double(Faraday::Response, status: 500, body: body, headers: headers, reason_phrase: 'Internal Server Error')
    end
    let(:headers) { { 'content-type' => 'application/vnd.api+json' } }
    let(:title) { 'Invalid cocina' }
    let(:body) do
      { errors: [{ status: '500', title: title, detail: 'unknown property releaseTags' }] }.to_json
    end

    context 'when the response is an invalid cocina error' do
      it 'raises an InvalidCocinaError' do
        expect { raise_exception }.to raise_error(Dor::Services::Client::InvalidCocinaError,
                                                  'Invalid cocina (unknown property releaseTags)') do |error|
          expect(error.errors.first['title']).to eq 'Invalid cocina'
        end
      end
    end

    context 'when the response is a 500 with a different title' do
      let(:title) { 'Internal Server Error' }

      it 'raises an UnexpectedResponse' do
        expect { raise_exception }.to raise_error(Dor::Services::Client::UnexpectedResponse) do |error|
          expect(error).not_to be_a(Dor::Services::Client::InvalidCocinaError)
        end
      end
    end

    context 'when the response is a 500 without a JSON:API body' do
      let(:headers) { { 'content-type' => 'text/html' } }
      let(:body) { '<html>Oops</html>' }

      it 'raises an UnexpectedResponse' do
        expect { raise_exception }.to raise_error(Dor::Services::Client::UnexpectedResponse) do |error|
          expect(error).not_to be_a(Dor::Services::Client::InvalidCocinaError)
        end
      end
    end
  end
end
