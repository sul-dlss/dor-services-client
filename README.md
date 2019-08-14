[![Gem Version](https://badge.fury.io/rb/dor-services-client.svg)](https://badge.fury.io/rb/dor-services-client)
[![Build Status](https://travis-ci.com/sul-dlss/dor-services-client.svg?branch=master)](https://travis-ci.com/sul-dlss/dor-services-client)
[![Code Climate](https://codeclimate.com/github/sul-dlss/dor-services-client/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/dor-services-client)
[![Code Climate Test Coverage](https://codeclimate.com/github/sul-dlss/dor-services-client/badges/coverage.svg)](https://codeclimate.com/github/sul-dlss/dor-services-client/coverage)

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
                                              token_header: Settings.dor_services.token_header)
end
```

Note that the client may **not** be used without first having been configured, and the `url` keyword is **required**. The `token` and `token_header` arguments are optional (though when using the client with staging and production servers, you will always need to supply these in practice). For more about dor-services-app's token-based authentication, see [its README](https://github.com/sul-dlss/dor-services-app#authentication).

## API Coverage

Dor::Services:Client provides a number of methods to simplify connecting to the RESTful HTTP API of dor-services-app. In this section we list all of the available methods, reflecting how much of the API the client covers:

```ruby
# For registering a non-existent object
objects_client = Dor::Services::Client.objects
objects_client.register(params: {})

# For performing operations on a known, registered object
object_client = Dor::Services::Client.object(object_identifier)
object_client.publish

# Copy metadata from Symphony into descMetadata
object_client.refresh_metadata

# Add constituents to an object (virtual-merge)
object_client.add_constituents(child_druids:)

# Send a notification to goobi
object_client.notify_goobi

# Manage versions
object_client.version.current
object_client.version.openable?(**params)
object_client.version.open(**params)
object_client.version.close(**params)

# Get the Dublin Core XML representation
object_client.metadata.dublin_core

# Get the public descriptive XML representation
object_client.metadata.descriptive
object_client.files.retrieve(filename: filename_string)
object_client.files.preserved_content(filename: filename_string, version: version_string)
object_client.files.list
object_client.release_tags.create(release: release, what: what, to: to, who: who)
object_client.sdr.content_diff(current_content: existing_content)
object_client.sdr.current_version
object_client.sdr.metadata(datastream: dsid)
object_client.sdr.signature_catalog

# Create and remove workspaces
object_client.workspace.create(source: object_path_string)
object_client.workspace.cleanup
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sul-dlss/dor-services-client

## Copyright

Copyright (c) 2018 Stanford Libraries. See LICENSE for details.
