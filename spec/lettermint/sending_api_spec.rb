# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::SendingAPI do
  let(:api_token) { 'test_project_token' }
  let(:base_url) { Lettermint::Configuration::DEFAULT_BASE_URL }

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

    it 'raises ArgumentError when api_token is whitespace only' do
      expect { described_class.new(api_token: '   ') }.to raise_error(ArgumentError, /API token cannot be empty/)
    end

    it 'accepts any non-empty token format' do
      # Unlike TeamAPI, SendingAPI accepts any token format
      expect { described_class.new(api_token: 'any_format_works') }.not_to raise_error
      expect { described_class.new(api_token: 'lm_proj_abc123') }.not_to raise_error
      expect { described_class.new(api_token: 'custom-token') }.not_to raise_error
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

  describe 'authentication header' do
    let(:client) { described_class.new(api_token: api_token) }

    it 'uses x-lettermint-token header for authentication' do
      stub = stub_request(:get, "#{base_url}/ping")
             .with(headers: { 'x-lettermint-token' => api_token })
             .to_return(status: 200, body: '{"ok":true}',
                        headers: { 'Content-Type' => 'application/json' })

      client.get('/ping')
      expect(stub).to have_been_requested
    end

    it 'does not use Authorization Bearer header' do
      stub = stub_request(:get, "#{base_url}/ping")
             .to_return(status: 200, body: '{"ok":true}',
                        headers: { 'Content-Type' => 'application/json' })

      client.get('/ping')

      # Verify the request was made without Bearer auth
      expect(stub).to have_been_requested
      expect(WebMock).to(have_requested(:get, "#{base_url}/ping")
        .with { |req| req.headers['Authorization'].nil? })
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

  describe 'HTTP method delegation' do
    let(:client) { described_class.new(api_token: api_token) }

    describe '#get' do
      it 'sends GET request and returns parsed response' do
        stub_request(:get, "#{base_url}/domains")
          .to_return(status: 200, body: '{"domains":[]}',
                     headers: { 'Content-Type' => 'application/json' })

        result = client.get('/domains')
        expect(result).to eq({ 'domains' => [] })
      end

      it 'passes query params' do
        stub_request(:get, "#{base_url}/messages?status=delivered")
          .to_return(status: 200, body: '{"messages":[]}',
                     headers: { 'Content-Type' => 'application/json' })

        result = client.get('/messages', params: { status: 'delivered' })
        expect(result).to eq({ 'messages' => [] })
      end

      it 'passes custom headers' do
        stub = stub_request(:get, "#{base_url}/data")
               .with(headers: { 'X-Request-Id' => 'req-123' })
               .to_return(status: 200, body: '{}',
                          headers: { 'Content-Type' => 'application/json' })

        client.get('/data', headers: { 'X-Request-Id' => 'req-123' })
        expect(stub).to have_been_requested
      end
    end

    describe '#post' do
      it 'sends POST request with JSON body and returns parsed response' do
        stub_request(:post, "#{base_url}/domains")
          .with(body: { domain: 'example.com' })
          .to_return(status: 201, body: '{"id":"dom_123"}',
                     headers: { 'Content-Type' => 'application/json' })

        result = client.post('/domains', data: { domain: 'example.com' })
        expect(result).to eq({ 'id' => 'dom_123' })
      end

      it 'works with empty data hash' do
        stub_request(:post, "#{base_url}/trigger")
          .with(body: {})
          .to_return(status: 200, body: '{"triggered":true}',
                     headers: { 'Content-Type' => 'application/json' })

        result = client.post('/trigger', data: {})
        expect(result).to eq({ 'triggered' => true })
      end
    end

    describe '#put' do
      it 'sends PUT request with JSON body' do
        stub_request(:put, "#{base_url}/domains/123")
          .with(body: { verified: true })
          .to_return(status: 200, body: '{"id":"123","verified":true}',
                     headers: { 'Content-Type' => 'application/json' })

        result = client.put('/domains/123', data: { verified: true })
        expect(result).to eq({ 'id' => '123', 'verified' => true })
      end
    end

    describe '#delete' do
      it 'sends DELETE request' do
        stub_request(:delete, "#{base_url}/domains/123")
          .to_return(status: 200, body: '{"deleted":true}',
                     headers: { 'Content-Type' => 'application/json' })

        result = client.delete('/domains/123')
        expect(result).to eq({ 'deleted' => true })
      end

      it 'handles 204 No Content' do
        stub_request(:delete, "#{base_url}/sessions/current")
          .to_return(status: 204, body: '')

        result = client.delete('/sessions/current')
        expect(result).to eq('')
      end
    end

    describe 'path normalization' do
      it 'handles path without leading slash' do
        stub = stub_request(:get, "#{base_url}/users")
               .to_return(status: 200, body: '[]',
                          headers: { 'Content-Type' => 'application/json' })

        client.get('users')
        expect(stub).to have_been_requested
      end
    end

    describe 'error propagation' do
      it 'raises ValidationError from underlying HttpClient' do
        stub_request(:post, "#{base_url}/invalid")
          .to_return(status: 422, body: '{"message":"Bad data","error":"validation_error"}',
                     headers: { 'Content-Type' => 'application/json' })

        expect { client.post('/invalid', data: {}) }
          .to raise_error(Lettermint::ValidationError)
      end

      it 'raises AuthenticationError on 401' do
        stub_request(:get, "#{base_url}/protected")
          .to_return(status: 401, body: '{"message":"Unauthorized"}',
                     headers: { 'Content-Type' => 'application/json' })

        expect { client.get('/protected') }
          .to raise_error(Lettermint::AuthenticationError)
      end

      it 'raises TimeoutError on timeout' do
        stub_request(:get, "#{base_url}/slow").to_raise(Faraday::TimeoutError)

        expect { client.get('/slow') }
          .to raise_error(Lettermint::TimeoutError)
      end
    end
  end

  describe 'backward compatibility' do
    it 'Lettermint::Client is an alias for SendingAPI' do
      expect(Lettermint::Client).to eq(described_class)
    end
  end
end
