# frozen_string_literal: true

RSpec.describe Dor::Services::Client::ReleaseTags do
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
        stub_request(:get, "https://dor-services.example.com/v1/objects/#{druid}/release_tags?public=false")
          .to_return(status: 200, body: '[{"to":"Searchworks","what":"self"},{"to":"Earthworks","what":"self"}]')
      end

      it 'lists administrative tags' do
        expect(request.map(&:to_h)).to eq([{ to: 'Searchworks', release: false, what: 'self' }, { to: 'Earthworks', release: false, what: 'self' }])
      end
    end

    context 'when API request succeeds and public release tags are requested' do
      subject(:request) { client.list(public: true) }

      before do
        stub_request(:get, "https://dor-services.example.com/v1/objects/#{druid}/release_tags?public=true")
          .to_return(status: 200, body: '[{"to":"Searchworks","what":"self"},{"to":"Earthworks","what":"self", "release": true}]')
      end

      it 'lists administrative tags' do
        expect(request.map(&:to_h)).to eq([{ to: 'Searchworks', release: false, what: 'self' }, { to: 'Earthworks', release: true, what: 'self' }])
      end
    end

    context 'when API request fails because of not found' do
      before do
        stub_request(:get, "https://dor-services.example.com/v1/objects/#{druid}/release_tags?public=false")
          .to_return(status: [404, 'object not found'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails due to unexpected response' do
      before do
        stub_request(:get, "https://dor-services.example.com/v1/objects/#{druid}/release_tags?public=false")
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end
  end

  describe '#create' do
    subject(:request) { client.create(tag: tag) }

    let(:tag) do
      Dor::Services::Client::ReleaseTag.new(what: 'self')
    end

    context 'when API request succeeds' do
      before do
        stub_request(:post, "https://dor-services.example.com/v1/objects/#{druid}/release_tags")
          .to_return(status: 201)
      end

      it 'posts tag' do
        expect(request).to be true
      end
    end

    context 'when API request fails because of conflict' do
      before do
        stub_request(:post, "https://dor-services.example.com/v1/objects/#{druid}/release_tags")
          .to_return(status: [409, 'conflict'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:post, "https://dor-services.example.com/v1/objects/#{druid}/release_tags")
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end
  end
end
