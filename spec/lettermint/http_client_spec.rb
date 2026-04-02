# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Lettermint::HttpClient do
  let(:base_url) { 'https://api.lettermint.co/v1' }
  let(:api_token) { 'test_token_123' }
  let(:timeout) { 30 }

  subject(:client) do
    described_class.new(api_token: api_token, base_url: base_url, timeout: timeout)
  end

  describe '#post' do
    it 'sends a POST request with JSON body' do
      stub = stub_request(:post, "#{base_url}/send")
             .with(
               body: { from: 'a@b.com', to: ['c@d.com'] },
               headers: { 'x-lettermint-token' => api_token, 'Content-Type' => 'application/json' }
             )
             .to_return(status: 202, body: '{"message_id":"msg_1","status":"queued"}',
                        headers: { 'Content-Type' => 'application/json' })

      result = client.post(path: '/send', data: { from: 'a@b.com', to: ['c@d.com'] })
      expect(stub).to have_been_requested
      expect(result).to eq({ 'message_id' => 'msg_1', 'status' => 'queued' })
    end

    it 'passes extra headers' do
      stub = stub_request(:post, "#{base_url}/send")
             .with(headers: { 'Idempotency-Key' => 'key-123' })
             .to_return(status: 202, body: '{"message_id":"msg_1","status":"queued"}',
                        headers: { 'Content-Type' => 'application/json' })

      client.post(path: '/send', data: {}, headers: { 'Idempotency-Key' => 'key-123' })
      expect(stub).to have_been_requested
    end
  end

  describe '#get' do
    it 'sends a GET request with query params' do
      stub = stub_request(:get, "#{base_url}/status?id=msg_1")
             .to_return(status: 200, body: '{"status":"delivered"}',
                        headers: { 'Content-Type' => 'application/json' })

      result = client.get(path: '/status', params: { 'id' => 'msg_1' })
      expect(stub).to have_been_requested
      expect(result).to eq({ 'status' => 'delivered' })
    end
  end

  describe '#put' do
    it 'sends a PUT request' do
      stub = stub_request(:put, "#{base_url}/resource")
             .to_return(status: 200, body: '{"ok":true}',
                        headers: { 'Content-Type' => 'application/json' })

      result = client.put(path: '/resource', data: { name: 'updated' })
      expect(stub).to have_been_requested
      expect(result).to eq({ 'ok' => true })
    end
  end

  describe '#delete' do
    it 'sends a DELETE request' do
      stub = stub_request(:delete, "#{base_url}/resource")
             .to_return(status: 200, body: '{"deleted":true}',
                        headers: { 'Content-Type' => 'application/json' })

      result = client.delete(path: '/resource')
      expect(stub).to have_been_requested
      expect(result).to eq({ 'deleted' => true })
    end
  end

  describe 'error handling' do
    it 'raises ValidationError on 422' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 422,
          body: '{"message":"Invalid email","error":"validation_error","errors":["bad field"]}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::ValidationError) { |e|
          expect(e.status_code).to eq(422)
          expect(e.error_type).to eq('validation_error')
          expect(e.message).to eq('Invalid email')
          expect(e.response_body).to include('errors' => ['bad field'])
        }
    end

    it 'raises ClientError on 400' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 400,
          body: '{"error":"Bad request body"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::ClientError) { |e|
          expect(e.status_code).to eq(400)
          expect(e.message).to eq('Bad request body')
        }
    end

    it 'raises AuthenticationError on 401' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 401,
          body: '{"message":"Invalid API token"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::AuthenticationError) { |e|
          expect(e.status_code).to eq(401)
          expect(e.message).to eq('Invalid API token')
        }
    end

    it 'raises AuthenticationError on 403' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 403,
          body: '{"message":"Forbidden"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::AuthenticationError) { |e|
          expect(e.status_code).to eq(403)
          expect(e.message).to eq('Forbidden')
        }
    end

    it 'raises RateLimitError on 429' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 429,
          body: '{"message":"Too many requests"}',
          headers: { 'Content-Type' => 'application/json', 'Retry-After' => '30' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::RateLimitError) { |e|
          expect(e.status_code).to eq(429)
          expect(e.retry_after).to eq(30)
          expect(e.message).to eq('Too many requests')
        }
    end

    it 'raises RateLimitError with nil retry_after when header is absent' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 429,
          body: '{"message":"Too many requests"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::RateLimitError) { |e|
          expect(e.retry_after).to be_nil
        }
    end

    it 'raises HttpRequestError on 500' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 500,
          body: '{"message":"Internal server error"}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::HttpRequestError) { |e|
          expect(e.status_code).to eq(500)
        }
    end

    it 'raises TimeoutError on Faraday timeout' do
      stub_request(:post, "#{base_url}/send").to_raise(Faraday::TimeoutError)

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::TimeoutError, /Request timeout/)
    end

    it 'raises ConnectionError on connection failure' do
      stub_request(:post, "#{base_url}/send").to_raise(Faraday::ConnectionFailed.new('refused'))

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::ConnectionError, /refused/) { |e|
          expect(e.original_exception).to be_a(Faraday::ConnectionFailed)
        }
    end
  end

  describe 'custom base URL' do
    it 'strips trailing slash' do
      custom_client = described_class.new(api_token: api_token, base_url: 'https://custom.api.co/v2/', timeout: 30)
      stub = stub_request(:get, 'https://custom.api.co/v2/ping')
             .to_return(status: 200, body: '{"ok":true}', headers: { 'Content-Type' => 'application/json' })

      custom_client.get(path: '/ping')
      expect(stub).to have_been_requested
    end
  end

  describe 'User-Agent header' do
    it 'includes SDK version and Ruby version' do
      stub = stub_request(:get, "#{base_url}/ping")
             .with(headers: { 'User-Agent' => "Lettermint/#{Lettermint::VERSION} (Ruby; ruby #{RUBY_VERSION})" })
             .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      client.get(path: '/ping')
      expect(stub).to have_been_requested
    end
  end
end
