# frozen_string_literal: true

require 'lettermint'
require 'webmock/rspec'

WebMock.disable_net_connect!

module FixtureHelpers
  FIXTURES_DIR = File.join(__dir__, 'fixtures')

  # Returns the raw contents of spec/fixtures/<name>, e.g. fixture('errors/not_found_api_error.json').
  def fixture(name)
    File.read(File.join(FIXTURES_DIR, name))
  end
end

RSpec.configure do |config|
  config.include FixtureHelpers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed
end
