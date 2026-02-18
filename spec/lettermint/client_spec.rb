# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::Client do
  let(:api_token) { 'test_token' }

  describe '#initialize' do
    it 'creates a client with required api_token' do
      client = described_class.new(api_token: api_token)
      expect(client.configuration.base_url).to eq(Lettermint::Configuration::DEFAULT_BASE_URL)
      expect(client.configuration.timeout).to eq(Lettermint::Configuration::DEFAULT_TIMEOUT)
    end

    it 'raises ArgumentError when api_token is nil' do
      expect { described_class.new(api_token: nil) }.to raise_error(ArgumentError, /API token cannot be empty/)
    end

    it 'raises ArgumentError when api_token is empty string' do
      expect { described_class.new(api_token: '') }.to raise_error(ArgumentError, /API token cannot be empty/)
    end

    it 'accepts custom base_url and timeout' do
      client = described_class.new(api_token: api_token, base_url: 'https://custom.co/v2', timeout: 60)
      expect(client.configuration.base_url).to eq('https://custom.co/v2')
      expect(client.configuration.timeout).to eq(60)
    end

    it 'accepts a configuration block' do
      client = described_class.new(api_token: api_token) do |c|
        c.timeout = 90
      end
      expect(client.configuration.timeout).to eq(90)
    end

    it 'falls back to Lettermint.configuration for defaults' do
      Lettermint.configure do |c|
        c.base_url = 'https://global.example.com/v1'
        c.timeout = 45
      end

      client = described_class.new(api_token: api_token)
      expect(client.configuration.base_url).to eq('https://global.example.com/v1')
      expect(client.configuration.timeout).to eq(45)
    ensure
      Lettermint.reset_configuration!
    end

    it 'prefers explicit kwargs over global configuration' do
      Lettermint.configure do |c|
        c.base_url = 'https://global.example.com/v1'
        c.timeout = 45
      end

      client = described_class.new(api_token: api_token, base_url: 'https://override.co/v1', timeout: 10)
      expect(client.configuration.base_url).to eq('https://override.co/v1')
      expect(client.configuration.timeout).to eq(10)
    ensure
      Lettermint.reset_configuration!
    end
  end

  describe '#email' do
    it 'returns an EmailMessage instance' do
      client = described_class.new(api_token: api_token)
      expect(client.email).to be_a(Lettermint::EmailMessage)
    end

    it 'returns a new instance each call' do
      client = described_class.new(api_token: api_token)
      msg_a = client.email
      msg_b = client.email
      expect(msg_a).not_to equal(msg_b)
    end
  end
end
