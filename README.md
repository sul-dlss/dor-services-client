[![Gem Version](https://badge.fury.io/rb/dor-services-client.svg)](https://badge.fury.io/rb/dor-services-client)
[![CircleCI](https://circleci.com/gh/sul-dlss/dor-services-client.svg?style=svg)](https://circleci.com/gh/sul-dlss/dor-services-client)
[![codecov](https://codecov.io/github/sul-dlss/dor-services-client/graph/badge.svg?token=dOdPMq8iIu)](https://codecov.io/github/sul-dlss/dor-services-client)

# Dor::Services::Client

Dor::Services::Client is a Ruby gem that acts as a client to the RESTful HTTP APIs provided by [dor-services-app](https://github.com/sul-dlss/dor-services-app). The gem is intended to be used as a replacement to the [dor-services gem](https://github.com/sul-dlss/dor-services)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dor-services-client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dor-services-client

## Usage

To configure and use the client, here's an example:

```ruby
require 'dor/services/client'

def do_the_thing
  # This API endpoint returns JSON
  response = client.objects.register(params: { druid: 'druid:123' })
  response[:pid] # => 'druid:123'
end

private

def client
  @client ||= Dor::Services::Client.configure(url: Settings.dor_services.url,
                                              token: Settings.dor_services.token,
                                              enable_get_retries: true)
end
```

Note:
* The client may **not** be used without first having been configured
* The `url` keyword is **required**.
* The `token` argument is optional (though when using the client with staging and production servers, you will always need to supply it in practice). For more about dor-services-app's token-based authentication, see [its README](https://github.com/sul-dlss/dor-services-app#authentication).
* The `enable_get_retries` argument is optional. When enabled, it will perform retries of `GET` requests only. This should only be used in situations in which blocking is not an issue, e.g., an asynchronous job.

## API Coverage

Dor::Services:Client provides a number of methods to simplify connecting to the RESTful HTTP API of dor-services-app. In this section we list all of the available methods, reflecting how much of the API the client covers. For details see the [API docs](https://www.rubydoc.info/github/sul-dlss/dor-services-client/main/Dor/Services/Client)

```ruby
# Perform operations on one or more objects
objects_client = Dor::Services::Client.objects

# Register a non-existent object
objects_client.register(params: {})
objects_client.register(params: {}, assign_doi: true, user_name: 'dude')

# Find object by source ID
objects_client.find(source_id: 'sul:abc123')

# Get status for a batch of objects
objects_client.statuses(object_ids: ['druid:bc123df4567', 'druid:bc987gh6543'])

# Interact with virtual objects
virtual_objects_client = Dor::Services::Client.virtual_objects

# Create a batch of virtual objects
virtual_objects_client.create(virtual_objects: [{ virtual_object_id: '', constituent_ids: [''] }])

# Retrieve background job results
background_jobs_client = Dor::Services::Client.background_job_results

# Show results of background job
background_jobs_client.show(job_id: 123)

# For performing operations on a known, registered object
object_client = Dor::Services::Client.object(object_identifier)

# Update an object
object_client.update(params: dro, user_name: 'dude', description: 'things change sometimes')

# Publish an object (push to PURL)
object_client.publish(workflow: 'releaseWF', lane_id: 'low')

# Start accessioning an object (initialize assemblyWF or specified workflow, and version object if needed)
object_client.accession.start(**versioning_params)

# Copy metadata from Symphony into descMetadata
object_client.refresh_descriptive_metadata_from_ils

# Apply defaults from the item's AdminPolicy to the item itself
object_client.apply_admin_policy_defaults

# Manage versions
object_client.version.inventory
object_client.version.current
# Returns a struct containing the status.
# Status includes whether the object is open, assembling, accessioning, or closeable.
# See also objects_client.statuses for getting statuses in batch.
object_client.version.status

# see dor-services-app openapi.yml for optional params
object_client.version.open(description: 'Changed title')
# see dor-services-app openapi.yml for optional params
object_client.version.close

# Manage user versions
object_client.user_version.inventory
object_client.user_version.find(2)
object_client.user_version.solr(2)
object_client.user_version.create(object_version: 3)
object_client.user_version.update(user_version: Dor::Services::Client::UserVersion::Version.new(version: 3, userVersion: 3, withdrawn: true))

# Return the Cocina metadata
object_client.find

# Returns "lite" Cocina metadata (excluding specified attributes)
object_client.find_lite(structural: false, geographic: false)

# Query for an object's collections
object_client.collections

# Query for a collection's members
object_client.members

# Create, update, destroy, and list administrative tags for an object
object_client.administrative_tags.create(tags: ['Tag : One', 'Tag : Two'])
object_client.administrative_tags.replace(tags: ['Tag : One', 'Tag : Two']) # like #create but removes current tags first
object_client.administrative_tags.update(current: 'Current : Tag', new: 'Replacement : Tag')
object_client.administrative_tags.destroy(tag: 'Delete : Me')
object_client.administrative_tags.list

# Create and list release tags for an object
object_client.release_tags.create(tag: Cocina::Models::Tag.new(to: 'Searchworks'))
object_client.release_tags.list
object_client.release_tags.list(public: true) # only public release tags (i.e. last published value)

# Create and list events for an object
object_client.events.create(type: type, data: data)
object_client.events.list

# Create workspaces
object_client.workspace.create(source: object_path_string)

# Reindex
object_client.reindex

# List workflows
object_client.workflows
# Find workflow
object_client.workflow('accessionWF').find
# Create workflow
object_client.workflow('etdSubmitWF').create(version: 2)
# Skip all workflow steps
object_client.workflow('accessionWF').skip_all(note: 'Cleaning up')
# Check if workflow is active for a given version
object_client.workflow(workflow_name).find.active_for?(version: 1)
# Check if workflow is complete for a given version
object_client.workflow(workflow_name).find.complete_for?(version: 1)
# Check if workflow is complete for an object
object_client.workflow(workflow_name).find.complete?

# Get the status of a workflow process
object_client.workflow('accessionWF').process('shelve').status
=> 'completed'
# Update workflow processes
object_client.workflow('accessionWF').process('shelve').update(status: 'completed')
object_client.workflow('accessionWF').process('shelve').update_error(error_msg: 'Something went wrong', error_text: 'Detailed error message')

# List milestones
object_client.milestones.list
# Get the date for a milestone
object_client.milestones.date(milestone_name: 'published')

# Search for administrative tags:
Dor::Services::Client.administrative_tags.search(q: 'Project')

# Get a list of workflow templates
Dor::Services::Client.workflows.templates
# Show a workflow template (e.g., to view its list of steps)
Dor::Services::Client.workflows.template('accessionWF')
```

## Asynchronous results

Some operations are asynchronous and they return a `Location` header that displays the
result of the job.  These jobs can be monitored by using `AsyncResult`.

```ruby
background_result_url = virtual_objects_client.create(virtual_objects: [{ parent_id: '', child_ids: [''] }])
result = virtual_objects_client.async_result(url: background_result_url)

# Checks the result one time
result.complete?

# Poll until complete
result.wait_until_complete

result.errors
# => [{ 'druid:foo' => ['druid:bar'] }]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sul-dlss/dor-services-client

## Copyright

Copyright (c) 2018 Stanford Libraries. See LICENSE for details.
