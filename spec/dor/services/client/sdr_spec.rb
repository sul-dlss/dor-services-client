# frozen_string_literal: true

RSpec.describe Dor::Services::Client::SDR do
  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:pid) { 'druid:1234' }

  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: pid) }

  describe '#signature_catalog' do
    subject(:request) { client.signature_catalog }

    before do
      allow(Deprecation).to receive(:warn)
      stub_request(:get, 'https://dor-services.example.com/v1/sdr/objects/druid:1234/manifest/signatureCatalog.xml')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) do
        <<~XML
                  <signatureCatalog objectId="druid:cs262tf9930" versionId="2" catalogDatetime="2016-02-18T07:24:36Z" fileCount="15" byteCount="20591" blockCount="29">
            <entry originalVersion="1" groupId="metadata" storagePath="contentMetadata.xml">
              <fileSignature size="487" md5="0e743ec90f97c8c4df49211144c46476" sha1="ee92c5335f0dcf1a943cc0640144a99e0e6152f0" sha256="a46d47e5a829b97ea877518e286f170e37ad411805ed9702d2a1f775b8f231df"/>
            </entry>
            <entry originalVersion="1" groupId="metadata" storagePath="descMetadata.xml">
              <fileSignature size="645" md5="52c2ec60211308416f1f55521972e2f2" sha1="7da9bdb9525c0865a2417942cc75cf30b896d209" sha256="369017df2e34eeae3263aabc03abd2f205f226744c8b5db38a90ac359739bd72"/>
            </entry>
            <entry originalVersion="1" groupId="metadata" storagePath="events.xml">
              <fileSignature size="144" md5="616d13adb7b8729f8b7e8818213fd48f" sha1="19f8387153cf9e6881e29717a50e94be71a3ad2e" sha256="9f7fd75fa57d669c0134f4d4621dc1bb0eb4d60f2cbb387185d9b8b9a0b34b52"/>
            </entry>
            <entry originalVersion="1" groupId="metadata" storagePath="identityMetadata.xml">
              <fileSignature size="875" md5="07aee5b3443821fc7e9842aa7a97f15e" sha1="6e2ed8489a7736b890a720c89ee93b3990156dd2" sha256="560533ede08d1bc4b3ea8eab0eb13c56eaa333a3115390aacb5dbbebb4bcad95"/>
            </entry>
            <entry originalVersion="1" groupId="metadata" storagePath="provenanceMetadata.xml">
              <fileSignature size="263" md5="f39cd6ef2f74ba653edf14079a9e0146" sha1="d7da1eea5172cee15659827a47f3e98295fcca46" sha256="cc5985f3bdb5516a18706af511a5e3fdf4388eab23a4aa41a8b6277340984282"/>
            </entry>
            <entry originalVersion="1" groupId="metadata" storagePath="relationshipMetadata.xml">
              <fileSignature size="458" md5="e1a1ee46ff583db06d1323fa307a0f0d" sha1="ee67a0ff6e808c2e972758dcd7b50152d353787b" sha256="a188a2600d98550061e6006de4508cccf2ed790095c96f558bbbf3a0740bfb87"/>
            </entry>
            <entry originalVersion="1" groupId="metadata" storagePath="rightsMetadata.xml">
              <fileSignature size="456" md5="f87c06080d91de40147af8dcd9128249" sha1="70c443c2a3b92bf8169dc70544b9ddeeab543764" sha256="f197ad811fb248ed26566d0b4b0a1521afeb0ad05c0f23a4e3ab813bcf1d0ef4"/>
            </entry>
            <entry originalVersion="1" groupId="metadata" storagePath="technicalMetadata.xml">
              <fileSignature size="2195" md5="31674292ee38b2f8a537b826b99d59a6" sha1="2acd5fdf9634f7556350c2bf8aa447a1d5df8220" sha256="5828c3e4d1ca1f378dfb3799ecb94335ec35198459ad33a29349e4b08fbccb6b"/>
            </entry>
            <entry originalVersion="1" groupId="metadata" storagePath="versionMetadata.xml">
              <fileSignature size="134" md5="4748af432b1a1131216bbc64fb6eeea7" sha1="1a0c31ae15e477ee4ff135a3691c25c753c31753" sha256="fb206337b553dbc2cf5da35ef08388661aadda52b1cbf6667fad260a0e90c915"/>
            </entry>
            <entry originalVersion="1" groupId="metadata" storagePath="workflows.xml">
              <fileSignature size="3780" md5="a2d1767f34ae8e6ccaf74c77cc9940ae" sha1="4b0f5afaec7c2e780f53e5cd597cf5e7e175260c" sha256="5f36ba79f4dcba8b7c2446899025ed1614ff59d0f95619daebfb3c53609bdf9a"/>
            </entry>
            <entry originalVersion="2" groupId="metadata" storagePath="events.xml">
              <fileSignature size="347" md5="60187f73f8611aec5aedc8e8914fc4a7" sha1="3978e29e9a0408e1904164dd37f3994a849e45f8" sha256="b64eb3c7c95dbd844c8032e27b98f371b1907f3673b0571f3117467999fbe0f3"/>
            </entry>
            <entry originalVersion="2" groupId="metadata" storagePath="provenanceMetadata.xml">
              <fileSignature size="263" md5="c681425ba66fc6a7a44506f4438e1c09" sha1="5288773193d0af6641be162d01b6ed31f83498e5" sha256="dc68347e935450a77820afa423fabbfc4f983061b763104dab16441135a06a73"/>
            </entry>
            <entry originalVersion="2" groupId="metadata" storagePath="relationshipMetadata.xml">
              <fileSignature size="622" md5="34fc12cf07c1686b9e48d5329c143f33" sha1="6c57cc8d5312ad6c48493bf0a4e0bf0da2db037f" sha256="2559ce0ec27bd5775d1744410666ea35b26cec41be7033b3e28df6f362a71158"/>
            </entry>
            <entry originalVersion="2" groupId="metadata" storagePath="versionMetadata.xml">
              <fileSignature size="259" md5="680b0c24f58de28503a296baa67fea28" sha1="56ab21bd8223c9cb5209326552d1ae99caa10b5a" sha256="397126eed5f3febd93b7f24705259951298adea2b9e17c8e7973a9f3ec21fe52"/>
            </entry>
            <entry originalVersion="2" groupId="metadata" storagePath="workflows.xml">
              <fileSignature size="9663" md5="03fcde6ef08b943cb9c75a57a364e222" sha1="a029abc076f09b72bd46fca2ce8c658358ef178f" sha256="4e2143a66d0273c51f3d8dee58d332bf4faf2b8f3ef99fee23fa5f1b596b7790"/>
            </entry>
          </signatureCatalog>
        XML
      end

      it 'returns a SignatureCatalog' do
        expect(request).to be_kind_of Moab::SignatureCatalog
      end
    end

    context 'when API request is not found' do
      let(:status) { [404, 'not found'] }
      let(:body) { 'i dunno?' }

      it 'returns a Moab::SignatureCatalog' do
        expect(request).to be_kind_of Moab::SignatureCatalog
      end
    end

    context 'when API request fails' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'i dunno?' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          'internal server error: 500 (i dunno?) for druid:1234')
      end
    end
  end

  describe '#content_diff' do
    subject(:response) { client.content_diff(current_content: '') }

    let(:body) { '<fileInventoryDifference />' }
    let(:status) { 200 }

    before do
      allow(Deprecation).to receive(:warn)
      stub_request(:post, 'https://dor-services.example.com/v1/sdr/objects/druid:1234/cm-inv-diff?subset=all')
        .to_return(status: status, body: body)
    end

    it 'fetches the file inventory difference from SDR' do
      expect(response.to_xml).to match(/<fileInventoryDifference/)
    end

    context 'with invalid parameters' do
      subject(:response) { client.content_diff(current_content: '', subset: 'bad') }

      it 'raises an error' do
        expect { response }.to raise_error ArgumentError
      end
    end

    context 'when API request fails' do
      let(:status) { [404, 'not found'] }
      let(:body) { 'i dunno?' }

      it 'raises an error' do
        expect { response }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                           'not found: 404 (i dunno?) for druid:1234')
      end
    end
  end

  describe '#metadata' do
    subject(:response) { client.metadata(datastream: 'technicalMetadata') }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/sdr/objects/druid:1234/metadata/technicalMetadata.xml')
        .to_return(status: status, body: body)
    end

    context 'when the object is found' do
      let(:status) { 200 }
      let(:body) { '<technicalMetadata/>' }

      it { is_expected.to eq '<technicalMetadata/>' }
    end

    context 'when the object is not found' do
      let(:status) { 404 }
      let(:body) { '' }

      it { is_expected.to be_nil }
    end

    context 'when there is a server error' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an error' do
        expect { response }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                           'internal server error: 500 (broken) for druid:1234')
      end
    end
  end

  describe '#current_version' do
    subject(:request) { client.current_version }

    before do
      allow(Deprecation).to receive(:warn)
      stub_request(:get, 'https://dor-services.example.com/v1/sdr/objects/druid:1234/current_version')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { '<currentVersion>2</currentVersion>' }

      it 'returns true' do
        expect(request).to eq 2
      end
    end

    context 'when API request responds with bad xml' do
      let(:status) { 200 }
      let(:body) { '<foo><bar>' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::MalformedResponse,
                                          'Unable to parse XML from current_version API call: <foo><bar>')
      end
    end

    context 'when API request fails' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          'internal server error: 500 (broken) for druid:1234')
      end
    end
  end
end
