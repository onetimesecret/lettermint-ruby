# frozen_string_literal: true

require_relative 'lib/lettermint/version'

Gem::Specification.new do |spec|
  spec.name = 'lettermint'
  spec.version = Lettermint::VERSION
  spec.authors = ['Delano']
  spec.email = ['gems@onetimesecret.com']

  spec.summary = 'Ruby SDK for the Lettermint transactional email API'
  spec.description = 'Send transactional emails and verify webhooks with the Lettermint API. ' \
                     'Provides a fluent builder interface, typed responses, and HMAC-SHA256 webhook verification.'
  spec.homepage = 'https://github.com/onetimesecret/lettermint-ruby'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?('spec/', 'examples/', '.git', '.rubocop', 'Rakefile', 'Gemfile')
    end
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '~> 2.0'
end
