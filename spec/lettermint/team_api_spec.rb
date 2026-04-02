# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::TeamAPI do
  let(:team_token) { 'lm_team_test123' }
  let(:base_url) { Lettermint::Configuration::DEFAULT_BASE_URL }

  describe '#initialize' do
    it 'creates a client with valid team token' do
      client = described_class.new(team_token: team_token)
      expect(client.configuration.base_url).to eq(Lettermint::Configuration::DEFAULT_BASE_URL)
      expect(client.configuration.timeout).to eq(Lettermint::Configuration::DEFAULT_TIMEOUT)
    end

    context 'token validation' do
      it 'raises ArgumentError when team_token is nil' do
        expect { described_class.new(team_token: nil) }
          .to raise_error(ArgumentError, /Team token cannot be empty/)
      end

      it 'raises ArgumentError when team_token is empty string' do
        expect { described_class.new(team_token: '') }
          .to raise_error(ArgumentError, /Team token cannot be empty/)
      end

      it 'raises ArgumentError when team_token is whitespace only' do
        expect { described_class.new(team_token: '   ') }
          .to raise_error(ArgumentError, /Team token cannot be empty/)
      end

      it 'raises ArgumentError when team_token does not start with lm_team_' do
        expect { described_class.new(team_token: 'invalid_token') }
          .to raise_error(ArgumentError, /Invalid team token format/)
      end

      it 'raises ArgumentError for project tokens' do
        expect { described_class.new(team_token: 'lm_proj_abc123') }
          .to raise_error(ArgumentError, /Invalid team token format/)
      end

      it 'raises ArgumentError for bearer tokens without prefix' do
        expect { described_class.new(team_token: 'some_random_token') }
          .to raise_error(ArgumentError, /Invalid team token format/)
      end

      it 'accepts token starting with lm_team_' do
        expect { described_class.new(team_token: 'lm_team_') }.not_to raise_error
        expect { described_class.new(team_token: 'lm_team_abc123xyz') }.not_to raise_error
        expect { described_class.new(team_token: 'lm_team_with-dashes') }.not_to raise_error
      end
    end

    it 'accepts custom base_url and timeout' do
      client = described_class.new(team_token: team_token, base_url: 'https://custom.co/v2', timeout: 60)
      expect(client.configuration.base_url).to eq('https://custom.co/v2')
      expect(client.configuration.timeout).to eq(60)
    end

    it 'accepts a configuration block' do
      client = described_class.new(team_token: team_token) do |c|
        c.timeout = 90
      end
      expect(client.configuration.timeout).to eq(90)
    end

    it 'falls back to Lettermint.configuration for defaults' do
      Lettermint.configure do |c|
        c.base_url = 'https://global.example.com/v1'
        c.timeout = 45
      end

      client = described_class.new(team_token: team_token)
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

      client = described_class.new(team_token: team_token, base_url: 'https://override.co/v1', timeout: 10)
      expect(client.configuration.base_url).to eq('https://override.co/v1')
      expect(client.configuration.timeout).to eq(10)
    ensure
      Lettermint.reset_configuration!
    end
  end

  describe 'authentication header' do
    let(:client) { described_class.new(team_token: team_token) }

    it 'uses Authorization Bearer header for authentication' do
      stub = stub_request(:get, "#{base_url}/ping")
             .with(headers: { 'Authorization' => "Bearer #{team_token}" })
             .to_return(status: 200, body: '{"ok":true}',
                        headers: { 'Content-Type' => 'application/json' })

      client.ping
      expect(stub).to have_been_requested
    end

    it 'does not use x-lettermint-token header' do
      stub = stub_request(:get, "#{base_url}/ping")
             .to_return(status: 200, body: '{"ok":true}',
                        headers: { 'Content-Type' => 'application/json' })

      client.ping

      expect(stub).to have_been_requested
      expect(WebMock).to(have_requested(:get, "#{base_url}/ping")
        .with { |req| req.headers['X-Lettermint-Token'].nil? })
    end
  end

  describe '#ping' do
    let(:client) { described_class.new(team_token: team_token) }

    it 'sends GET request to /ping' do
      stub_request(:get, "#{base_url}/ping")
        .to_return(status: 200, body: '{"ok":true}',
                   headers: { 'Content-Type' => 'application/json' })

      result = client.ping
      expect(result).to eq({ 'ok' => true })
    end
  end

  describe 'resource accessors' do
    let(:client) { described_class.new(team_token: team_token) }

    describe '#team' do
      it 'returns a Team resource instance' do
        expect(client.team).to be_a(Lettermint::Resources::Team)
      end

      it 'returns a new instance each call' do
        team_a = client.team
        team_b = client.team
        expect(team_a).not_to equal(team_b)
      end
    end

    describe '#domains' do
      it 'returns a Domains resource instance' do
        expect(client.domains).to be_a(Lettermint::Resources::Domains)
      end
    end

    describe '#projects' do
      it 'returns a Projects resource instance' do
        expect(client.projects).to be_a(Lettermint::Resources::Projects)
      end
    end

    describe '#webhooks' do
      it 'returns a Webhooks resource instance' do
        expect(client.webhooks).to be_a(Lettermint::Resources::Webhooks)
      end
    end

    describe '#messages' do
      it 'returns a Messages resource instance' do
        expect(client.messages).to be_a(Lettermint::Resources::Messages)
      end
    end

    describe '#suppressions' do
      it 'returns a Suppressions resource instance' do
        expect(client.suppressions).to be_a(Lettermint::Resources::Suppressions)
      end
    end

    describe '#stats' do
      it 'returns a Stats resource instance' do
        expect(client.stats).to be_a(Lettermint::Resources::Stats)
      end
    end

    describe '#routes' do
      it 'returns a Routes resource instance' do
        expect(client.routes).to be_a(Lettermint::Resources::Routes)
      end
    end
  end

  describe 'error propagation' do
    let(:client) { described_class.new(team_token: team_token) }

    it 'raises AuthenticationError on 401' do
      stub_request(:get, "#{base_url}/ping")
        .to_return(status: 401, body: '{"message":"Invalid token"}',
                   headers: { 'Content-Type' => 'application/json' })

      expect { client.ping }.to raise_error(Lettermint::AuthenticationError)
    end

    it 'raises AuthenticationError on 403' do
      stub_request(:get, "#{base_url}/ping")
        .to_return(status: 403, body: '{"message":"Forbidden"}',
                   headers: { 'Content-Type' => 'application/json' })

      expect { client.ping }.to raise_error(Lettermint::AuthenticationError)
    end

    it 'raises TimeoutError on timeout' do
      stub_request(:get, "#{base_url}/ping").to_raise(Faraday::TimeoutError)

      expect { client.ping }.to raise_error(Lettermint::TimeoutError)
    end

    it 'raises ConnectionError on connection failure' do
      stub_request(:get, "#{base_url}/ping").to_raise(Faraday::ConnectionFailed.new('refused'))

      expect { client.ping }.to raise_error(Lettermint::ConnectionError)
    end
  end
end
