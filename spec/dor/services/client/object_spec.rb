# frozen_string_literal: true

RSpec.describe Dor::Services::Client::Object do
  subject(:client) { described_class.new(connection: connection, version: 'v1', object_identifier: druid) }

  before do
    Dor::Services::Client.configure(url: 'https://dor-services.example.com', token: '123')
  end

  let(:connection) { Dor::Services::Client.instance.send(:connection) }
  let(:druid) { 'druid:bc123df4567' }

  describe '#object_identifier' do
    it 'returns the injected druid' do
      expect(client.object_identifier).to eq druid
    end
  end

  describe '#collections' do
    let(:collections) { instance_double(Dor::Services::Client::Collections, collections: true) }

    before do
      allow(Dor::Services::Client::Collections).to receive(:new).and_return(collections)
    end

    it 'delegates to the Client::Collections' do
      client.collections
      expect(collections).to have_received(:collections)
    end
  end

  describe '#members' do
    let(:members) { instance_double(Dor::Services::Client::Members, members: true) }

    before do
      allow(Dor::Services::Client::Members).to receive(:new).and_return(members)
    end

    it 'delegates to the Client::Members' do
      client.members
      expect(members).to have_received(:members)
    end
  end

  describe '#administrative_tags' do
    it 'returns an instance of Client::AdministrativeTags' do
      expect(client.administrative_tags).to be_instance_of Dor::Services::Client::AdministrativeTags
    end
  end

  describe '#release_tags' do
    it 'returns an instance of Client::ReleaseTags' do
      expect(client.release_tags).to be_instance_of Dor::Services::Client::ReleaseTags
    end
  end

  describe '#accession' do
    it 'returns an instance of Client::Accession' do
      expect(client.accession).to be_instance_of Dor::Services::Client::Accession
    end
  end

  describe '#workspace' do
    it 'returns an instance of Client::Workspace' do
      expect(client.workspace).to be_instance_of Dor::Services::Client::Workspace
    end
  end

  describe '#version' do
    it 'returns an instance of Client::ObjectVersion' do
      expect(client.version).to be_instance_of Dor::Services::Client::ObjectVersion
    end
  end

  describe '#user_version' do
    it 'returns an instance of Client::UserVersion' do
      expect(client.user_version).to be_instance_of Dor::Services::Client::UserVersion
    end
  end

  describe '#events' do
    it 'returns an instance of Client::Events' do
      expect(client.events).to be_instance_of Dor::Services::Client::Events
    end
  end

  describe '#milestones' do
    it 'returns an instance of Client::Milestones' do
      expect(client.milestones).to be_instance_of Dor::Services::Client::Milestones
    end
  end

  describe '#workflows' do
    let(:object_workflows) { instance_double(Dor::Services::Client::ObjectWorkflows, list: true) }

    before do
      allow(Dor::Services::Client::ObjectWorkflows).to receive(:new).and_return(object_workflows)
    end

    it 'delegates to the Client::ObjectWorkflows' do
      client.workflows
      expect(object_workflows).to have_received(:list)
    end
  end

  describe '#workflow' do
    let(:object_workflow) { instance_double(Dor::Services::Client::ObjectWorkflow) }

    it 'returns an instance of Client::ObjectWorkflow' do
      # This is not in a `before` block because the other tests in the `describe` block don't rely on this being spied on
      allow(Dor::Services::Client::ObjectWorkflow).to receive(:new).and_return(object_workflow)
      expect(client.workflow('accessionWF')).to be object_workflow
      expect(Dor::Services::Client::ObjectWorkflow).to have_received(:new).with(
        connection: connection,
        version: 'v1',
        object_identifier: druid,
        workflow_name: 'accessionWF'
      )
    end

    context 'when called with a different workflow name' do
      it 'refreshes the memoized instance' do
        expect(client.workflow('accessionWF')).not_to eq client.workflow('registrationWF')
      end
    end

    context 'when called with nil workflow name' do
      it 'raises an ArgumentError' do
        expect { client.workflow(nil) }.to raise_error(ArgumentError, /`workflow_name` argument cannot be blank/)
      end
    end

    context 'when called with blank workflow name' do
      it 'raises an ArgumentError' do
        expect { client.workflow('') }.to raise_error(ArgumentError, /`workflow_name` argument cannot be blank/)
      end
    end
  end

  describe '#find' do
    subject(:model) { client.find(validate: validate) }

    let(:cocina) { build(:dro, id: 'druid:bc123df4567') }

    let(:validate) { false }

    let(:status) { 200 }

    before do
      stub_request(:get, 'https://dor-services.example.com/v1/objects/druid:bc123df4567')
        .to_return(status: status,
                   body: cocina.to_json,
                   headers: {
                     'Last-Modified' => 'Wed, 03 Mar 2021 18:58:00 GMT',
                     'X-Created-At' => 'Wed, 01 Jan 2021 12:58:00 GMT',
                     'X-Served-By' => 'Awesome webserver',
                     'ETag' => 'W/"d41d8cd98f00b204e9800998ecf8427e"'
                   })
    end

    context 'when API request succeeds with DRO' do
      it 'returns the cocina model' do
        expect(model.externalIdentifier).to eq 'druid:bc123df4567'
        expect(model.lock).to eq('W/"d41d8cd98f00b204e9800998ecf8427e"')
        expect(model.created.to_s).to eq('2021-01-01T12:58:00+00:00')
        expect(model.modified.to_s).to eq('2021-03-03T18:58:00+00:00')
      end
    end

    context 'when API request succeeds with Collection' do
      let(:cocina) { build(:collection, id: 'druid:bc123df4567') }

      it 'returns the cocina model' do
        expect(model.externalIdentifier).to eq 'druid:bc123df4567'
      end
    end

    context 'when validating' do
      let(:validate) { true }

      before do
        allow(Cocina::Models).to receive(:build).and_return(cocina)
      end

      it 'validates' do
        model
        expect(Cocina::Models).to have_received(:build).with(cocina.to_h.deep_stringify_keys, validate: true)
      end
    end

    context 'when not validating' do
      before do
        allow(Cocina::Models).to receive(:build).and_return(cocina)
      end

      it 'validates' do
        model
        expect(Cocina::Models).to have_received(:build).with(cocina.to_h.deep_stringify_keys, validate: false)
      end
    end
  end

  describe '#find_lite' do
    subject(:model) { client.find_lite(structural: false, geographic: false, description: false) }

    before do
      stub_request(:post, 'https://dor-services.example.com/graphql')
        .with(
          body: '{"query":"{\\n  cocinaObject(externalIdentifier: \"druid:bc123df4567\") {\\n    ' \
                'externalIdentifier\\ntype\\nversion\\nlabel\\ncocinaVersion\\nadministrative\\naccess\\n' \
                'identification\\n  }\\n}\\n"}',
          headers: {
            'Authorization' => 'Bearer 123',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(status: 200, body: body, headers: {})
    end

    context 'when API request succeeds with a DRO' do
      let(:body) do
        {
          data: {
            cocinaObject: {
              externalIdentifier: druid,
              type: 'https://cocina.sul.stanford.edu/models/object',
              version: 1,
              label: 'factory DRO label',
              cocinaVersion: '0.90.0',
              administrative: {
                hasAdminPolicy: 'druid:hv992ry2431'
              },
              access: {
                view: 'dark',
                download: 'none',
                controlledDigitalLending: false
              },
              identification: {
                sourceId: 'sul:1234',
                catalogLinks: []
              }
            }
          }
        }.to_json
      end

      it 'returns the cocina lite model' do
        expect(model).to be_instance_of Cocina::Models::DROLite
        expect(model.externalIdentifier).to eq druid
        expect(model.description).to be_nil
        expect(model.access.to_h).to eq(
          {
            view: 'dark',
            download: 'none',
            controlledDigitalLending: false
          }
        )
      end
    end

    context 'when API request succeeds with an AdminPolicy' do
      # AdminPolicy has fewer fields than a DRO. This tests that extra fields returned by
      # GraphQL are ignored.
      let(:body) do
        {
          data: {
            cocinaObject: {
              externalIdentifier: druid,
              type: 'https://cocina.sul.stanford.edu/models/admin_policy',
              version: 1,
              label: 'factory APO label',
              cocinaVersion: '0.90.0',
              administrative: {
                roles: [],
                hasAgreement: 'druid:hp308wm0436',
                accessTemplate: {
                  view: 'world',
                  download: 'world',
                  controlledDigitalLending: false
                },
                hasAdminPolicy: 'druid:hv992ry2431',
                registrationWorkflow: [],
                collectionsForRegistration: []
              },
              access: nil,
              identification: nil
            }
          }
        }.to_json
      end

      it 'returns the cocina lite model' do
        expect(model).to be_instance_of Cocina::Models::AdminPolicyLite
      end
    end

    context 'when API request succeeds with not found' do
      let(:body) do
        {
          data: nil,
          errors: [
            {
              message: 'Cocina object not found',
              locations: [
                {
                  line: 2,
                  column: 3
                }
              ],
              path: [
                'cocinaObject'
              ]
            }
          ]
        }.to_json
      end

      it 'raises NotFoundResponse' do
        expect { model }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request succeeds with other error' do
      let(:body) do
        {
          data: nil,
          errors: [
            {
              message: 'Uggh, something went wrong',
              locations: [
                {
                  line: 2,
                  column: 3
                }
              ],
              path: [
                'cocinaObject'
              ]
            }
          ]
        }.to_json
      end

      it 'raises UnexpectedResponse' do
        expect { model }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end
  end

  describe '#update' do
    let(:created) { DateTime.parse('Wed, 01 Jan 2021 12:58:00 GMT') }

    let(:modified) { DateTime.parse('Wed, 03 Mar 2021 18:58:00 GMT') }

    let(:lock) { 'W/"d41d8cd98f00b204e9800998ecf8427e"' }

    let(:dro) do
      build(:dro, id: 'druid:bc123df4567')
    end

    let(:dro_with_metadata) do
      Cocina::Models.with_metadata(dro, lock, created: created, modified: modified)
    end

    let(:json) do
      dro.to_json
    end

    context 'when API request succeeds with DRO' do
      subject(:model) { client.update(params: dro_with_metadata) }

      before do
        stub_request(:patch, 'https://dor-services.example.com/v1/objects/druid:bc123df4567')
          .with(
            body: json,
            headers: {
              'If-Match' => lock,
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            }
          )
          .to_return(status: 200,
                     body: json,
                     headers: {
                       'Last-Modified' => 'Wed, 04 Mar 2021 18:58:00 GMT',
                       'X-Created-At' => 'Wed, 02 Jan 2021 12:58:00 GMT',
                       'X-Served-By' => 'Awesome webserver',
                       'ETag' => 'W/"e541d8cd98f00b204e9800998ecf8427f"'
                     })
      end

      it 'returns the cocina model' do
        expect(model.externalIdentifier).to eq 'druid:bc123df4567'
        expect(model.lock).to eq('W/"e541d8cd98f00b204e9800998ecf8427f"')
      end
    end

    context 'when some event data is provided' do
      subject(:model) { client.update(params: dro_with_metadata, user_name: who, description: description) }

      let(:who) { 'test_user' }
      let(:description) { 'update stuff' }

      before do
        stub_request(:patch, "https://dor-services.example.com/v1/objects/druid:bc123df4567?event_description=#{description}&user_name=#{who}")
          .with(
            body: json,
            headers: {
              'If-Match' => lock,
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            }
          )
          .to_return(status: 200,
                     body: json,
                     headers: {
                       'Last-Modified' => 'Wed, 04 Mar 2021 18:58:00 GMT',
                       'X-Created-At' => 'Wed, 02 Jan 2021 12:58:00 GMT',
                       'X-Served-By' => 'Awesome webserver',
                       'ETag' => 'W/"e541d8cd98f00b204e9800998ecf8427f"'
                     })
      end

      it 'sends the event data in the patch request in the querystring' do
        expect(model.externalIdentifier).to eq 'druid:bc123df4567'
        expect(model.lock).to eq('W/"e541d8cd98f00b204e9800998ecf8427f"')
        expect(WebMock).to have_requested(:patch, "https://dor-services.example.com/v1/objects/druid:bc123df4567?event_description=#{description}&user_name=#{who}")
          .with(body: json, headers: { 'If-Match' => lock, 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
      end
    end

    context 'when provided a hash' do
      it 'raises' do
        expect { client.update(params: dro_with_metadata.to_h) }.to raise_error(ArgumentError)
      end
    end

    context 'when missing lock' do
      it 'raises' do
        expect { client.update(params: dro) }.to raise_error(ArgumentError)
      end
    end

    context 'when skipping lock' do
      subject(:model) { client.update(params: dro, skip_lock: true) }

      let(:event_data) { {} }

      before do
        stub_request(:patch, 'https://dor-services.example.com/v1/objects/druid:bc123df4567')
          .with(
            body: json,
            headers: {
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            }
          )
          .to_return(status: 200,
                     body: json,
                     headers: {
                       'Last-Modified' => 'Wed, 04 Mar 2021 18:58:00 GMT',
                       'X-Created-At' => 'Wed, 02 Jan 2021 12:58:00 GMT',
                       'X-Served-By' => 'Awesome webserver',
                       'ETag' => 'W/"e541d8cd98f00b204e9800998ecf8427f"'
                     })
      end

      it 'returns the cocina model' do
        expect(model.externalIdentifier).to eq 'druid:bc123df4567'
        expect(model.lock).to eq('W/"e541d8cd98f00b204e9800998ecf8427f"')
      end
    end
  end

  describe '#refresh_descriptive_metadata_from_ils' do
    subject(:request) { client.refresh_descriptive_metadata_from_ils }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/refresh_metadata')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns true' do
        expect(request).to be true
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
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end
  end

  describe '#apply_admin_policy_defaults' do
    subject(:request) { client.apply_admin_policy_defaults }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/apply_admin_policy_defaults')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns true' do
        expect(request).to be true
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
  end

  describe '#destroy' do
    subject(:request) { client.destroy }

    context 'when API request succeeds with no user name' do
      before do
        stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:bc123df4567')
          .to_return(status: 204)
      end

      it 'when API request succeeds' do
        expect(request).to be true
      end
    end

    context 'when API request succeeds with a username' do
      subject(:request) { client.destroy(user_name: 'sandimetz') }

      before do
        stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:bc123df4567?user_name=sandimetz')
          .to_return(status: 204)
      end

      it 'when API request succeeds' do
        expect(request).to be true
      end
    end

    context 'when API request fails because of not found' do
      before do
        stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:bc123df4567')
          .to_return(status: [404, 'object not found'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::NotFoundResponse)
      end
    end

    context 'when API request fails due to unexpected response' do
      before do
        stub_request(:delete, 'https://dor-services.example.com/v1/objects/druid:bc123df4567')
          .to_return(status: [500, 'something is amiss'])
      end

      it 'raises an error' do
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end
  end

  describe '#reindex' do
    subject(:request) { client.reindex }

    before do
      stub_request(:post, 'https://dor-services.example.com/v1/objects/druid:bc123df4567/reindex')
        .to_return(status: status)
    end

    context 'when API request succeeds' do
      let(:status) { 200 }

      it 'returns true' do
        expect(request).to be true
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
        expect { request }.to raise_error(Dor::Services::Client::UnexpectedResponse)
      end
    end
  end
end
