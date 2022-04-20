# frozen_string_literal: true

RSpec.describe Dor::Services::Client::AdministrativeTags do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: druid) }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:druid) { 'druid:bc123df4567' }

  describe '#list' do
    subject(:request) { client.list }

    context 'when API request succeeds' do
      before do
        stub_request(:get, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags")
          .to_return(status: 200, body: '["Registered By : mjgiarlo","Process : Content Type : Map"]')
      end

      it 'lists administrative tags' do
        expect(request).to eq(['Registered By : mjgiarlo', 'Process : Content Type : Map'])
      end
    end

    context 'when API request fails because of not found' do
      before do
        stub_request(:get, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags")
          .to_return(status: [404, 'object not found'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails due to unexpected response' do
      before do
        stub_request(:get, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags")
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end
  end

  describe '#create' do
    subject(:request) { client.create(tags: ['Registered By : mjgiarlo', 'Process : Content Type : Map']) }

    context 'when API request succeeds' do
      before do
        stub_request(:post, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags")
          .to_return(status: 201)
      end

      it 'posts tags' do
        expect(request).to be true
      end
    end

    context 'when API request fails because of conflict' do
      before do
        stub_request(:post, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags")
          .to_return(status: [409, 'conflict'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags")
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end
  end

  describe '#replace' do
    subject(:request) { client.replace(tags: ['Registered By : mjgiarlo', 'Process : Content Type : Map']) }

    context 'when API request succeeds' do
      before do
        stub_request(:post, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags")
          .to_return(status: 201)
      end

      it 'replaces tags' do
        expect(request).to be true
      end
    end

    context 'when API request fails because of conflict' do
      before do
        stub_request(:post, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags")
          .to_return(status: [409, 'conflict'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags")
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end
  end

  describe '#update' do
    subject(:request) { client.update(current: current_tag, new: new_tag) }

    let(:current_tag) { 'Process : Content Type : Map' }
    let(:new_tag) { 'Process : Content Type : Not A Map At All Actually' }

    context 'when API request succeeds' do
      before do
        stub_request(:put, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags/#{CGI.escape(current_tag)}")
          .to_return(status: 204)
      end

      it 'updates the administrative tag' do
        expect(request).to be true
      end
    end

    context 'when API request fails because of not found' do
      before do
        stub_request(:put, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags/#{CGI.escape(current_tag)}")
          .to_return(status: [404, 'object not found'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails because of conflict' do
      before do
        stub_request(:put, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags/#{CGI.escape(current_tag)}")
          .to_return(status: [409, 'conflict'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end

    context 'when API request fails due to unexpected response' do
      before do
        stub_request(:put, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags/#{CGI.escape(current_tag)}")
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end
  end

  describe '#destroy' do
    subject(:request) { client.destroy(tag: tag) }

    let(:tag) { 'Process : Content Type : Map' }

    context 'when API request succeeds' do
      before do
        stub_request(:delete, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags/#{CGI.escape(tag)}")
          .to_return(status: 204)
      end

      it 'updates the administrative tag' do
        expect(request).to be true
      end
    end

    context 'when API request fails because of not found' do
      before do
        stub_request(:delete, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags/#{CGI.escape(tag)}")
          .to_return(status: [404, 'object not found'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails due to unexpected response' do
      before do
        stub_request(:delete, "https://dor-services.example.com/v1/objects/#{druid}/administrative_tags/#{CGI.escape(tag)}")
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "something is amiss: 500 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY}) for #{druid}")
      end
    end
  end
end
