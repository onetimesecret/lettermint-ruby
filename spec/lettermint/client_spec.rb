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
