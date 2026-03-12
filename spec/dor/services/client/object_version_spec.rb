# frozen_string_literal: true

RSpec.describe Dor::Services::Client::ObjectVersion do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: druid) }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123', enable_get_retries: false)
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:druid) { 'druid:bc123df4567' }

  describe '#find' do
    subject(:model) { client.find(version) }

    let(:body) { build(:dro, id: druid) }
    let(:status) { 200 }
    let(:version) { 2 }

    before do
      stub_request(:get, "https://dor-services.example.com/v1/objects/#{druid}/versions/#{version}")
        .to_return(status: status,
                   body: body.to_json,
                   headers: {
                     'Last-Modified' => 'Wed, 03 Mar 2021 18:58:00 GMT',
                     'X-Created-At' => 'Wed, 01 Jan 2021 12:58:00 GMT',
                     'X-Served-By' => 'Awesome webserver',
                     'ETag' => 'W/"d41d8cd98f00b204e9800998ecf8427e"'
                   })
    end

    it 'returns the cocina model' do
      expect(model.externalIdentifier).to eq(druid)
      expect(model.lock).to eq('W/"d41d8cd98f00b204e9800998ecf8427e"')
      expect(model.created.to_s).to eq('2021-01-01T12:58:00+00:00')
      expect(model.modified.to_s).to eq('2021-03-03T18:58:00+00:00')
    end

    context 'when response is unexpected' do
      let(:status) { 404 }

      it 'raises the unexpected response' do
        expect { model }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when response is HTTP 409' do
      let(:druid) { 'druid:zc797bh1369' }
      let(:message) do
        'Multiple value, groupedValue, structuredValue, and parallelValue in description: note1, note2, note3'
      end
      let(:status) { 409 }
      let(:version) { 3 }
      # rubocop:disable Layout/LineLength
      let(:body) do
        {
          errors: [{
            status: status,
            detail: message,
            title: 'Object is not valid cocina',
            meta: {
              json: {
                cocinaVersion: '0.75.0',
                type: 'https://cocina.sul.stanford.edu/models/map',
                externalIdentifier: 'druid:zc797bh1369',
                label: 'Naka Shina gomanbun no ichi Buko',
                version: 3,
                access:
                  { 'view' => 'world',
                    'license' => 'https://creativecommons.org/publicdomain/mark/1.0/',
                    'download' => 'world',
                    'copyright' => 'This work has been identified as being free of known restrictions under copyright law, including all related and neighboring rights. You can copy, modify, distribute and perform the work, even for commercial purposes, all without asking permission.',
                    'controlledDigitalLending' => false,
                    'useAndReproductionStatement' => 'Image from the Map Collections courtesy Stanford University Libraries. This item is in the public domain. There are no restrictions on use. If you have questions, please contact Branner Earth Sciences Library & Map Collections at brannerlibrary@stanford.edu.' },
                administrative: { 'hasAdminPolicy' => 'druid:xs835jp8197' },
                description:
                  { 'form' =>
                    [{ 'uri' => 'http://id.loc.gov/vocabulary/marcgt/map', 'note' => [], 'type' => 'genre', 'value' => 'map', 'source' => { 'code' => 'marcgt', 'note' => [] }, 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                     { 'uri' => 'http://id.loc.gov/vocabulary/marcgt/gov', 'note' => [], 'type' => 'genre', 'value' => 'government publication',
                       'source' => { 'code' => 'marcgt', 'note' => [] }, 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                     { 'uri' => 'http://id.loc.gov/vocabulary/contentTypes/cri', 'note' => [], 'type' => 'genre', 'value' => 'cartographic image',
                       'source' => { 'code' => 'rdacontent', 'note' => [] }, 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                     { 'uri' => 'https://id.loc.gov/authorities/genreForms/gf2011026387', 'note' => [], 'type' => 'genre', 'value' => 'Maps',
                       'source' => { 'code' => 'lcgft', 'note' => [] }, 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                     { 'uri' => 'https://id.loc.gov/authorities/genreForms/gf2011026697', 'note' => [], 'type' => 'genre', 'value' => 'Topographic maps',
                       'source' => { 'code' => 'lcgft', 'note' => [] }, 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                     { 'note' => [], 'type' => 'form', 'value' => 'map', 'source' => { 'code' => 'marccategory', 'note' => [] }, 'appliesTo' => [], 'identifier' => [],
                       'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                     { 'note' => [], 'type' => 'form', 'value' => 'map', 'source' => { 'code' => 'marcsmd', 'note' => [] }, 'appliesTo' => [], 'identifier' => [],
                       'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                     { 'note' => [], 'type' => 'resource type', 'value' => 'cartographic', 'source' => { 'note' => [], 'value' => 'MODS resource types' }, 'appliesTo' => [],
                       'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                     { 'note' => [], 'type' => 'extent', 'value' => 'maps ; 36 x 52 cm or smaller', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [],
                       'parallelValue' => [], 'structuredValue' => [] },
                     { 'note' => [], 'type' => 'media', 'value' => 'unmediated', 'source' => { 'code' => 'rdamedia', 'note' => [] }, 'appliesTo' => [], 'identifier' => [],
                       'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                     { 'note' => [], 'type' => 'carrier', 'value' => 'sheet', 'source' => { 'code' => 'rdacarrier', 'note' => [] }, 'appliesTo' => [], 'identifier' => [],
                       'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                     { 'note' => [], 'type' => 'map scale', 'value' => 'Scale 1:50,000', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [],
                       'structuredValue' => [] }],
                    'note' =>
                    [{ 'note' => [],
                       'value' => 'Relief shown by contours and spot heights',
                       'appliesTo' => [],
                       'identifier' => [],
                       'groupedValue' => [],
                       'parallelValue' =>
                       [{ 'note' => [], 'value' => 'Confidential "Gunji Gokuh" printed on upper right margin', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                        { 'note' => [], 'value' => 'Confidential "軍事極祕" printed on upper right margin.', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [],
                          'parallelValue' => [], 'structuredValue' => [] }],
                       'structuredValue' => [] },
                     { 'note' => [],
                       'value' => 'Includes index map to adjoining sheets',
                       'appliesTo' => [],
                       'identifier' => [],
                       'groupedValue' => [],
                       'parallelValue' =>
                       [{ 'note' => [], 'value' => "\"Gunji Himitsu (tōbun no aida Shinajihen ni okeru guntai ni kagiri 'Bugaihi' atsukai ni junsu)\"", 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                        { 'note' => [], 'value' => '"軍事秘密 (當分ノ間支那事変地二於ケル軍隊二限リ「部外秘」扱二準ス)"', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [],
                          'structuredValue' => [] }],
                       'structuredValue' => [] },
                     { 'note' => [],
                       'value' => 'Sheets individually subtitled and numbered, e.g. "和橋鎮","2號."',
                       'appliesTo' => [],
                       'identifier' => [],
                       'groupedValue' => [],
                       'parallelValue' =>
                       [{ 'note' => [], 'value' => 'Some maps: Surveyed Chūkaminkoku 24 [1935], Revised Shōwa 15 [1940]', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                        { 'note' => [], 'value' => '修正圖: 中華民國24年測圖 (安徽省測量局/参謀本部陸地測量総局) 昭和15年修正測量/加描　(昭和14年12月撮影).', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [],
                          'parallelValue' => [], 'structuredValue' => [] }],
                       'structuredValue' => [] }],
                    'purl' => 'https://purl.stanford.edu/zc797bh1369',
                    'event' =>
                    [{ 'date' =>
                       [{ 'note' => [],
                          'type' => 'publication',
                          'encoding' => { 'code' => 'marc', 'note' => [] },
                          'appliesTo' => [],
                          'identifier' => [],
                          'groupedValue' => [],
                          'parallelValue' => [],
                          'structuredValue' =>
                          [
                            { 'note' => [], 'type' => 'start', 'value' => '1940', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [],
                              'structuredValue' => [] }, { 'note' => [], 'type' => 'end', 'value' => '194u', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] }
                          ] }],
                       'note' => [{ 'note' => [], 'type' => 'issuance', 'value' => 'monographic', 'source' => { 'note' => [], 'value' => 'MODS issuance terms' }, 'appliesTo' => [],
                                    'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] }],
                       'location' => [{ 'code' => 'ja', 'note' => [], 'source' => { 'code' => 'marccountry', 'note' => [] }, 'appliesTo' => [], 'identifier' => [],
                                        'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] }],
                       'identifier' => [],
                       'contributor' => [],
                       'parallelEvent' => [],
                       'structuredValue' => [] }],
                    'title' =>
                    [{ 'note' => [],
                       'appliesTo' => [],
                       'identifier' => [],
                       'groupedValue' => [],
                       'parallelValue' =>
                       [{ 'note' => [],
                          'status' => 'primary',
                          'appliesTo' => [],
                          'identifier' => [],
                          'groupedValue' => [],
                          'parallelValue' => [],
                          'structuredValue' => [{ 'note' => [], 'type' => 'main title', 'value' => 'Naka Shina gomanbun no ichi Buko', 'appliesTo' => [], 'identifier' => [],
                                                  'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] }] },
                        { 'note' => [], 'value' => '中支那五万分一 蕉湖', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] }],
                       'structuredValue' => [] }],
                    'subject' =>
                    [{ 'note' => [],
                       'appliesTo' => [],
                       'identifier' => [],
                       'groupedValue' => [],
                       'parallelValue' =>
                       [{ 'note' => [],
                          'source' => { 'code' => 'lcsh', 'note' => [] },
                          'appliesTo' => [],
                          'identifier' => [],
                          'groupedValue' => [],
                          'parallelValue' => [],
                          'structuredValue' =>
                          [{ 'note' => [], 'type' => 'place', 'value' => 'Wuhu (China)', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                           { 'note' => [], 'type' => 'genre', 'value' => 'Maps', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [],
                             'structuredValue' => [] }] },
                        { 'note' => [], 'type' => 'place', 'value' => '蕪湖', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [],
                          'structuredValue' => [] }],
                       'structuredValue' => [] },
                     { 'note' => [],
                       'appliesTo' => [],
                       'identifier' => [],
                       'groupedValue' => [],
                       'parallelValue' =>
                       [{ 'note' => [],
                          'source' => { 'code' => 'lcsh', 'note' => [] },
                          'appliesTo' => [],
                          'identifier' => [],
                          'groupedValue' => [],
                          'parallelValue' => [],
                          'structuredValue' =>
                          [{ 'note' => [], 'type' => 'place', 'value' => 'Anhui Sheng (China)', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                           { 'note' => [], 'type' => 'genre', 'value' => 'Maps', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [],
                             'structuredValue' => [] }] },
                        { 'note' => [], 'type' => 'place', 'value' => '安徽省', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [],
                          'structuredValue' => [] }],
                       'structuredValue' => [] },
                     { 'code' => 'a-cc-an', 'note' => [], 'type' => 'place', 'source' => { 'code' => 'marcgac', 'note' => [] }, 'appliesTo' => [], 'identifier' => [],
                       'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                     { 'code' => 'a-cc', 'note' => [], 'type' => 'place', 'source' => { 'code' => 'marcgac', 'note' => [] }, 'appliesTo' => [], 'identifier' => [],
                       'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                     { 'note' => [], 'type' => 'classification', 'value' => 'G7824 .W83 s50 .J3', 'source' => { 'code' => 'lcc', 'note' => [] }, 'appliesTo' => [],
                       'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] }],
                    'language' =>
                    [{ 'code' => 'jpn', 'note' => [], 'source' => { 'code' => 'iso639-2b', 'note' => [] }, 'appliesTo' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] },
                     { 'code' => 'ch', 'note' => [], 'source' => { 'code' => 'iso639-2b', 'note' => [] }, 'appliesTo' => [], 'groupedValue' => [], 'parallelValue' => [],
                       'structuredValue' => [] },
                     { 'code' => 'i', 'note' => [], 'source' => { 'code' => 'iso639-2b', 'note' => [] }, 'appliesTo' => [], 'groupedValue' => [], 'parallelValue' => [],
                       'structuredValue' => [] }],
                    'geographic' => [],
                    'identifier' => [],
                    'contributor' =>
                    [{ 'name' =>
                       [{ 'note' => [],
                          'appliesTo' => [],
                          'identifier' => [],
                          'groupedValue' => [],
                          'parallelValue' =>
                          [{ 'uri' => 'http://id.loc.gov/authorities/names/n79079547',
                             'note' => [],
                             'appliesTo' => [],
                             'identifier' => [],
                             'groupedValue' => [],
                             'parallelValue' => [],
                             'structuredValue' => [
                               { 'note' => [], 'value' => 'Japan', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [],
                                 'structuredValue' => [] }, { 'note' => [], 'value' => 'Rikuchi Sokuryōbu', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] }
                             ] },
                           { 'note' => [],
                             'appliesTo' => [],
                             'identifier' => [],
                             'groupedValue' => [],
                             'parallelValue' => [],
                             'structuredValue' => [
                               { 'note' => [], 'value' => 'Japan', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [],
                                 'structuredValue' => [] }, { 'note' => [], 'value' => '陸地測量部', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] }
                             ] }],
                          'structuredValue' => [] }],
                       'note' => [],
                       'role' => [{ 'note' => [], 'value' => 'cartographer', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [],
                                    'structuredValue' => [] }],
                       'type' => 'organization',
                       'identifier' => [],
                       'parallelContributor' => [] }],
                    'adminMetadata' =>
                    { 'note' => [{ 'note' => [], 'type' => 'record origin', 'value' => 'Converted from MARCXML to MODS version 3.7 using MARC21slim2MODS3-7_SDR_v2-5.xsl (SUL 3.7 version 2.5 20210421; LC Revision 1.140 20200717)', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] }],
                      'event' =>
                      [{ 'date' => [{ 'note' => [], 'value' => 'yymmdd', 'encoding' => { 'code' => 'marc', 'note' => [] }, 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] }],
                         'note' => [],
                         'type' => 'creation',
                         'location' => [],
                         'identifier' => [],
                         'contributor' => [],
                         'parallelEvent' => [],
                         'structuredValue' => [] },
                       { 'date' => [{ 'note' => [], 'value' => '20210703012158.0', 'encoding' => { 'code' => 'iso8601', 'note' => [] }, 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] }],
                         'note' => [],
                         'type' => 'modification',
                         'location' => [],
                         'identifier' => [],
                         'contributor' => [],
                         'parallelEvent' => [],
                         'structuredValue' => [] }],
                      'language' => [{ 'code' => 'eng', 'note' => [], 'source' => { 'code' => 'iso639-2b', 'note' => [] }, 'appliesTo' => [], 'groupedValue' => [],
                                       'parallelValue' => [], 'structuredValue' => [] }],
                      'identifier' => [{ 'note' => [], 'type' => 'SIRSI', 'value' => 'a13900011', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [],
                                         'parallelValue' => [], 'structuredValue' => [] }],
                      'contributor' =>
                      [{ 'name' => [{ 'code' => 'CSt-ES', 'note' => [], 'source' => { 'code' => 'marcorg', 'note' => [] }, 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [], 'structuredValue' => [] }],
                         'note' => [],
                         'role' => [{ 'note' => [], 'value' => 'original cataloging agency', 'appliesTo' => [], 'identifier' => [], 'groupedValue' => [], 'parallelValue' => [],
                                      'structuredValue' => [] }],
                         'type' => 'organization',
                         'identifier' => [],
                         'parallelContributor' => [] }],
                      'metadataStandard' => [{ 'code' => 'rda', 'note' => [] }] },
                    'marcEncodedData' => [],
                    'relatedResource' => [] },
                identification: { 'barcode' => '36105228367251', 'sourceId' => 'sul:36105228367251',
                                  'catalogLinks' => [{ 'catalog' => 'folio', 'refresh' => true, 'sortKey' => '0046', 'partLabel' => 'G7824 .W83 S50 .J3 SHEET 88', 'catalogRecordId' => 'a13900011' }, { 'catalog' => 'symphony', 'refresh' => false, 'catalogRecordId' => '13900011' }] },
                structural:
                  { 'contains' =>
                    [{ 'type' => 'https://cocina.sul.stanford.edu/models/resources/image',
                       'label' => 'Image 1',
                       'version' => 2,
                       'structural' =>
                       { 'contains' =>
                         [{ 'size' => 311_569_496,
                            'type' => 'https://cocina.sul.stanford.edu/models/file',
                            'label' => 'zc797bh1369_0001.tif',
                            'access' => { 'view' => 'world', 'download' => 'world', 'controlledDigitalLending' => false },
                            'version' => 2,
                            'filename' => 'zc797bh1369_0001.tif',
                            'hasMimeType' => 'image/tiff',
                            'presentation' => { 'width' => 13_922, 'height' => 12_422 },
                            'administrative' => { 'shelve' => false, 'publish' => false, 'sdrPreserve' => true },
                            'hasMessageDigests' => [{ 'type' => 'sha1', 'digest' => '8f35f49bffb96f5ed86933de9cb66d7e9aa08c08' },
                                                    { 'type' => 'md5', 'digest' => '68c974507416ead3bed323778692d3bd' }],
                            'externalIdentifier' => 'https://cocina.sul.stanford.edu/file/zc797bh1369-zc797bh1369_1/zc797bh1369_0001.tif' },
                          { 'size' => 32_550_874,
                            'type' => 'https://cocina.sul.stanford.edu/models/file',
                            'label' => 'zc797bh1369_0001.jp2',
                            'access' => { 'view' => 'world', 'download' => 'world', 'controlledDigitalLending' => false },
                            'version' => 2,
                            'filename' => 'zc797bh1369_0001.jp2',
                            'hasMimeType' => 'image/jp2',
                            'presentation' => { 'width' => 13_922, 'height' => 12_422 },
                            'administrative' => { 'shelve' => true, 'publish' => true, 'sdrPreserve' => false },
                            'hasMessageDigests' => [{ 'type' => 'sha1', 'digest' => 'a5c450baea60ab32b205abd1b50b5fce9e204d79' },
                                                    { 'type' => 'md5', 'digest' => 'aaa3a92c5535d47923de9259da0467a1' }],
                            'externalIdentifier' => 'https://cocina.sul.stanford.edu/file/zc797bh1369-zc797bh1369_1/zc797bh1369_0001.jp2' }] },
                       'externalIdentifier' => 'https://cocina.sul.stanford.edu/fileSet/zc797bh1369-zc797bh1369_1' }],
                    'isMemberOf' => [],
                    'hasMemberOrders' => [] }
              }
            }
          }]
        }
      end
      # rubocop:enable Layout/LineLength

      it 'returns the cocina model without validation' do
        expect(model.type).to eq('https://cocina.sul.stanford.edu/models/map')
        expect(model.error_message).to eq('Multiple value, groupedValue, structuredValue, and parallelValue in description: note1, note2, note3')
      end
    end
  end

  describe '#current_version' do
    subject(:request) { client.current }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current')
        .to_return(status: status, body: body)
    end

    let(:status) { [0, 'overwritten below when necessary'] }
    let(:body) { 'overwritten below when necessary' }

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { '2' }

      it 'returns the value' do
        expect(request).to eq '2'
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }
      let(:body) { '' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "unauthorized: 401 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end

    context 'when connection fails' do
      before do
        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current')
          .to_raise(Faraday::ConnectionFailed.new('end of file reached'))
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::ConnectionFailed, 'unable to reach dor-services-app: end of file reached')
      end
    end

    context 'when retriable error' do
      let(:logger) { instance_double(Logger, info: nil) }

      before do
        Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123', logger: logger)

        stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current')
          .to_return(status: 503, body: '')
          .then.to_return(status: 200, body: '2')
      end

      it 'logs retries' do
        expect(request).to eq '2'
        expect(logger).to have_received(:info)
          .with('Retry 1 for https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current due to Faraday::RetriableResponse ()')
      end
    end
  end

  describe '#discard' do
    subject(:request) { client.discard }

    let(:status) { [209, 'no content'] }

    before do
      stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      it 'does not raise' do
        expect { request }.not_to raise_error
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          "unauthorized: 401 (#{Dor::Services::Client::ResponseErrorFormatter::DEFAULT_BODY})")
      end
    end

    context 'when connection fails' do
      before do
        stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current')
          .to_raise(Faraday::ConnectionFailed.new('end of file reached'))
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::ConnectionFailed, 'unable to reach dor-services-app: end of file reached')
      end
    end
  end

  describe '#inventory' do
    subject(:request) { client.inventory }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) do
        <<~JSON
          {"versions":[
            {"versionId":1,"message":"Initial version","cocina":true},
            {"versionId":2,"message":"Updated","cocina":false}
          ]}
        JSON
      end

      it 'returns the list of versions' do
        expect(request).to eq [
          described_class::Version.new(versionId: 1, message: 'Initial version', cocina: true),
          described_class::Version.new(versionId: 2, message: 'Updated', cocina: false)
        ]
        expect(request.first.version).to eq 1
        expect(request.first.cocina?).to be true
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }
      let(:body) { '' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnauthorizedResponse)
      end
    end

    context 'when connection fails' do
      before do
        allow_any_instance_of(Faraday::Adapter::NetHttp).to receive(:call).and_raise(Faraday::ConnectionFailed.new('end of file reached'))
      end

      let(:status) { 555 }
      let(:body) { '' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::ConnectionFailed, 'unable to reach dor-services-app: end of file reached')
      end
    end
  end

  describe '#open_new_version' do
    subject(:request) { client.open(**params) }

    let(:params) { {} }

    let(:created) { DateTime.parse('Wed, 01 Jan 2021 12:58:00 GMT') }

    let(:modified) { DateTime.parse('Wed, 03 Mar 2021 18:58:00 GMT') }

    let(:lock) { 'W/"d41d8cd98f00b204e9800998ecf8427e"' }

    let(:dro) do
      build(:dro, id: 'druid:bc123df4567')
    end

    let(:dro_with_metadata) do
      Cocina::Models.with_metadata(dro, lock, created: created, modified: modified)
    end

    let(:headers) do
      {
        'Last-Modified' => 'Wed, 03 Mar 2021 18:58:00 GMT',
        'X-Created-At' => 'Wed, 01 Jan 2021 12:58:00 GMT',
        'ETag' => 'W/"d41d8cd98f00b204e9800998ecf8427e"'
      }
    end

    let(:body) { dro.to_json }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: status, body: body,
                   headers: headers)
    end

    context 'with additional params' do
      let(:status) { 200 }
      let(:params) { { foo: 'bar' } }

      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions?foo=bar')
          .with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: status, body: body, headers: headers)
      end

      it 'returns cocina model with metadata' do
        expect(request).to eq dro_with_metadata
      end
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns cocina model with metadata' do
        expect(request).to eq dro_with_metadata
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an UnexpectedResponse error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          'internal server error: 500 (broken)')
      end
    end
  end

  describe '#close_version' do
    subject(:request) { client.close(**params) }

    let(:params) { {} }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current/close')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: status, body: body)
    end

    context 'with additional params' do
      let(:status) { 200 }
      let(:body) { 'version 2 closed' }
      let(:params) { { user_name: 'lelands', description: nil } }

      before do
        stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/current/close?user_name=lelands')
          .with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: status, body: body)
      end

      it 'returns confirmation message' do
        expect(request).to eq body
      end
    end

    context 'when API request succeeds' do
      let(:status) { 200 }
      let(:body) { 'version 2 closed' }

      it 'returns confirmation message' do
        expect(request).to eq body
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails' do
      let(:status) { [500, 'internal server error'] }
      let(:body) { 'broken' }

      it 'raises an UnexpectedResponse error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse,
                                          'internal server error: 500 (broken)')
      end
    end
  end

  describe '#status' do
    subject(:request) { client.status }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/status')
        .to_return(status: status, body: body)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      let(:body) do
        <<~JSON
          {"versionId":1,"open":true,"openable":false,"assembling":true,"accessioning":false,"closeable":true,"discardable":false,"versionDescription":"Initial version"}
        JSON
      end

      it 'returns the list of versions' do
        expect(request).to eq described_class::VersionStatus.new(versionId: 1, open: true, openable: false,
                                                                 assembling: true, accessioning: false, closeable: true,
                                                                 discardable: false, versionDescription: 'Initial version')
        expect(request.version).to eq 1
        expect(request).to be_open
        expect(request).not_to be_openable
        expect(request).to be_assembling
        expect(request).not_to be_accessioning
        expect(request).not_to be_closed
        expect(request).to be_closeable
        expect(request).not_to be_discardable
        expect(request.version_description).to eq 'Initial version'
      end
    end

    context 'when API request returns 404' do
      let(:status) { [404, 'not found'] }
      let(:body) { '' }

      it 'raises a NotFoundResponse exception' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails' do
      let(:status) { [401, 'unauthorized'] }
      let(:body) { '' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnauthorizedResponse)
      end
    end

    context 'when connection fails' do
      before do
        allow_any_instance_of(Faraday::Adapter::NetHttp).to receive(:call).and_raise(Faraday::ConnectionFailed.new('end of file reached'))
      end

      let(:status) { 555 }
      let(:body) { '' }

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::ConnectionFailed, 'unable to reach dor-services-app: end of file reached')
      end
    end
  end

  describe '#solr' do
    subject(:solr) { client.solr(2, validate: validate) }

    let(:expected_solr) do
      {
        'id' => druid,
        'current_version_isi' => 1,
        'obj_label_tesim' => 'Test DRO',
        'modified_latest_dttsi' => '2024-07-03T12:32:16Z',
        'created_at_dttsi' => '2024-07-03T12:32:16Z',
        'is_governed_by_ssim' => 'info:fedora/druid:hy787xj5878',
        'objectType_ssim' => ['item']
      }
    end
    let(:validate) { true }

    before do
      stub_request(:get, "https://dor-services.example.com/v1/objects/druid:bc123df4567/versions/2/solr?validate=#{validate}")
        .to_return(status: 200,
                   body: expected_solr.to_json)
    end

    it 'returns the solr document' do
      expect(solr).to eq expected_solr
    end

    context 'with validation turned off' do
      let(:validate) { false }

      it 'returns the solr document' do
        expect(solr).to eq expected_solr
      end
    end
  end
end
