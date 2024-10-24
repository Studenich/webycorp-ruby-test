# frozen_string_literal: true

require 'vcr'
require 'faraday'
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :faraday, :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data('<STRIPE_SECRET_KEY>') { ENV.fetch('STRIPE_SECRET_KEY', nil) }

  config.allow_http_connections_when_no_cassette = true
  config.default_cassette_options = {
    match_requests_on: %i[method uri],
    record: :new_episodes
  }
end
