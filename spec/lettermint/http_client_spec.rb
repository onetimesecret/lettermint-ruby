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

    it 'raises ValidationError with error_type taken from the ApiError code' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 422,
          body: '{"error":{"code":"VALIDATION_FAILED","message":"Recipient is invalid.","details":{"to":["invalid"]}}}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::ValidationError) { |e|
          expect(e.error_type).to eq('VALIDATION_FAILED')
          expect(e.code).to eq('VALIDATION_FAILED')
          expect(e.message).to eq('Recipient is invalid.')
          expect(e.details).to eq({ 'to' => ['invalid'] })
        }
    end

    it 'raises ValidationError with default error_type when the ApiError has no String code' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 422,
          body: '{"error":{"code":42,"message":"Recipient is invalid."}}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::ValidationError) { |e|
          expect(e.error_type).to eq('ValidationError')
          expect(e.code).to be_nil
          expect(e.message).to eq('Recipient is invalid.')
        }
    end

    it 'raises ValidationError with default error_type when the body has no error key' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 422,
          body: '{"message":"Invalid email","errors":{"to":["bad field"]}}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::ValidationError) { |e|
          expect(e.error_type).to eq('ValidationError')
          expect(e.message).to eq('Invalid email')
          expect(e.code).to be_nil
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
          expect(e.message).to eq('HTTP 400')
          expect(e.code).to eq('Bad request body')
          expect(e.details).to be_nil
        }
    end

    it 'raises ClientError with message, code and details from an ApiError body' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 400,
          body: '{"error":{"code":"INVALID_REQUEST","message":"Body is malformed.","details":{"field":"to"}}}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::ClientError) { |e|
          expect(e.status_code).to eq(400)
          expect(e.message).to eq('Body is malformed.')
          expect(e.code).to eq('INVALID_REQUEST')
          expect(e.details).to eq({ 'field' => 'to' })
        }
    end

    it 'exposes details as an Array when the API returns one' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 400,
          body: '{"error":{"code":"MULTIPLE_ISSUES","message":"Fields are invalid.","details":[{"field":"to"}]}}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::ClientError) { |e|
          expect(e.code).to eq('MULTIPLE_ISSUES')
          expect(e.details).to eq([{ 'field' => 'to' }])
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

    it 'raises AuthenticationError with code from an ApiError body' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 401,
          body: '{"error":{"code":"UNAUTHENTICATED","message":"Invalid API token.","details":null}}',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::AuthenticationError) { |e|
          expect(e.status_code).to eq(401)
          expect(e.code).to eq('UNAUTHENTICATED')
          expect(e.message).to eq('Invalid API token.')
          expect(e.details).to be_nil
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

    it 'raises HttpRequestError on non-JSON error response body' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 500,
          body: 'Internal Server Error',
          headers: { 'Content-Type' => 'text/plain' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::HttpRequestError) { |e|
          expect(e.status_code).to eq(500)
          expect(e.response_body).to eq('Internal Server Error')
          expect(e.message).to eq('HTTP 500')
          expect(e.code).to be_nil
        }
    end

    it 'keeps a non-Hash JSON error body as parsed' do
      stub_request(:post, "#{base_url}/send")
        .to_return(
          status: 500,
          body: '["unexpected"]',
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::HttpRequestError) { |e|
          expect(e.response_body).to eq(['unexpected'])
          expect(e.message).to eq('HTTP 500')
          expect(e.code).to be_nil
        }
    end

    context 'on 404' do
      let(:path) { '/domains/dom_missing' }

      def stub_not_found(body, content_type: 'application/json')
        stub_request(:get, "#{base_url}#{path}")
          .to_return(status: 404, body: body, headers: { 'Content-Type' => content_type })
      end

      it 'raises NotFoundError with code and message from an ApiError body' do
        body = fixture('errors/not_found_api_error.json')
        stub_not_found(body)

        expect { client.get(path: path) }
          .to raise_error(Lettermint::NotFoundError) { |e|
            expect(e.status_code).to eq(404)
            expect(e.code).to eq('RESOURCE_NOT_FOUND')
            expect(e.message).to eq('Domain not found.')
            expect(e.details).to be_nil
            expect(e.response_body).to eq(JSON.parse(body))
          }
      end

      it 'raises NotFoundError with code only from a string error body' do
        stub_not_found(fixture('errors/not_found_string_error.json'))

        expect { client.get(path: path) }
          .to raise_error(Lettermint::NotFoundError) { |e|
            expect(e.code).to eq('not_found')
            expect(e.message).to eq('HTTP 404')
            expect(e.details).to be_nil
          }
      end

      it 'raises NotFoundError with message only from an ErrorMessage body' do
        stub_not_found(fixture('errors/not_found_error_message.json'))

        expect { client.get(path: path) }
          .to raise_error(Lettermint::NotFoundError) { |e|
            expect(e.message).to eq('Domain not found.')
            expect(e.code).to be_nil
            expect(e.details).to be_nil
          }
      end

      it 'raises NotFoundError with the raw HTML when a proxy answers with text/html' do
        stub_not_found(fixture('errors/not_found_proxy.html'), content_type: 'text/html')

        expect { client.get(path: path) }
          .to raise_error(Lettermint::NotFoundError) { |e|
            expect(e.status_code).to eq(404)
            expect(e.response_body).to be_a(String)
            expect(e.response_body).to include('<title>404 Not Found</title>')
            expect(e.code).to be_nil
            expect(e.message).to eq('HTTP 404')
          }
      end

      it 'raises NotFoundError with nil response_body when the body is empty' do
        stub_not_found('')

        expect { client.get(path: path) }
          .to raise_error(Lettermint::NotFoundError) { |e|
            expect(e.response_body).to be_nil
            expect(e.message).to eq('HTTP 404')
            expect(e.code).to be_nil
          }
      end

      it 'is rescued by rescue Lettermint::HttpRequestError' do
        stub_not_found(fixture('errors/not_found_api_error.json'))

        rescued = begin
          client.get(path: path)
        rescue Lettermint::HttpRequestError => e
          e
        end

        expect(rescued).to be_a(Lettermint::NotFoundError)
      end
    end

    it 'raises ConnectionError on SSL failure' do
      stub_request(:post, "#{base_url}/send").to_raise(Faraday::SSLError.new('certificate verify failed'))

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::ConnectionError, /SSL error:.*certificate verify failed/) { |e|
          expect(e.original_exception).to be_a(Faraday::SSLError)
        }
    end

    it 'raises ResponseParsingError on invalid JSON response' do
      stub_request(:post, "#{base_url}/send").to_raise(Faraday::ParsingError.new('unexpected token'))

      expect { client.post(path: '/send', data: {}) }
        .to raise_error(Lettermint::ResponseParsingError, /API response parsing failed/) { |e|
          expect(e.original_exception).to be_a(Faraday::ParsingError)
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
