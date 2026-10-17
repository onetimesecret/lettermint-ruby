# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Lettermint error hierarchy' do
  describe Lettermint::Error do
    it 'inherits from StandardError' do
      expect(Lettermint::Error.ancestors).to include(StandardError)
    end
  end

  describe Lettermint::HttpRequestError do
    subject(:error) do
      described_class.new(message: 'Bad request', status_code: 500, response_body: { 'error' => 'fail' })
    end

    it 'inherits from Lettermint::Error' do
      expect(error).to be_a(Lettermint::Error)
    end

    it 'exposes status_code' do
      expect(error.status_code).to eq(500)
    end

    it 'exposes response_body' do
      expect(error.response_body).to eq({ 'error' => 'fail' })
    end

    it 'has the correct message' do
      expect(error.message).to eq('Bad request')
    end

    it 'defaults response_body to nil' do
      err = described_class.new(message: 'fail', status_code: 503)
      expect(err.response_body).to be_nil
    end

    it 'exposes code and details' do
      err = described_class.new(message: 'fail', status_code: 503, code: 'UPSTREAM_DOWN', details: { 'retry' => true })
      expect(err.code).to eq('UPSTREAM_DOWN')
      expect(err.details).to eq({ 'retry' => true })
    end

    it 'defaults code and details to nil' do
      expect(error.code).to be_nil
      expect(error.details).to be_nil
    end
  end

  describe Lettermint::ValidationError do
    subject(:error) do
      described_class.new(message: 'Invalid field', error_type: 'validation_error', response_body: { 'errors' => [] })
    end

    it 'inherits from HttpRequestError' do
      expect(error).to be_a(Lettermint::HttpRequestError)
    end

    it 'hardcodes status_code to 422' do
      expect(error.status_code).to eq(422)
    end

    it 'exposes error_type' do
      expect(error.error_type).to eq('validation_error')
    end

    it 'exposes code and details' do
      err = described_class.new(message: 'Invalid field', error_type: 'VALIDATION_FAILED',
                                code: 'VALIDATION_FAILED', details: { 'to' => ['invalid'] })
      expect(err.code).to eq('VALIDATION_FAILED')
      expect(err.details).to eq({ 'to' => ['invalid'] })
    end

    it 'defaults code and details to nil' do
      expect(error.code).to be_nil
      expect(error.details).to be_nil
    end
  end

  describe Lettermint::ClientError do
    subject(:error) { described_class.new(message: 'Bad request') }

    it 'inherits from HttpRequestError' do
      expect(error).to be_a(Lettermint::HttpRequestError)
    end

    it 'hardcodes status_code to 400' do
      expect(error.status_code).to eq(400)
    end

    it 'exposes code and details' do
      err = described_class.new(message: 'Bad request', code: 'INVALID_REQUEST', details: [{ 'field' => 'to' }])
      expect(err.code).to eq('INVALID_REQUEST')
      expect(err.details).to eq([{ 'field' => 'to' }])
    end

    it 'defaults code and details to nil' do
      expect(error.code).to be_nil
      expect(error.details).to be_nil
    end
  end

  describe Lettermint::NotFoundError do
    subject(:error) { described_class.new(message: 'Domain not found.') }

    it 'inherits from HttpRequestError' do
      expect(error).to be_a(Lettermint::HttpRequestError)
    end

    it 'hardcodes status_code to 404' do
      expect(error.status_code).to eq(404)
    end

    it 'has the correct message' do
      expect(error.message).to eq('Domain not found.')
    end

    it 'exposes code and details' do
      err = described_class.new(message: 'Domain not found.', code: 'RESOURCE_NOT_FOUND', details: { 'id' => 'dom_1' })
      expect(err.code).to eq('RESOURCE_NOT_FOUND')
      expect(err.details).to eq({ 'id' => 'dom_1' })
    end

    it 'defaults code and details to nil' do
      expect(error.code).to be_nil
      expect(error.details).to be_nil
    end

    it 'exposes response_body' do
      body = { 'error' => { 'code' => 'RESOURCE_NOT_FOUND', 'message' => 'Domain not found.' } }
      err = described_class.new(message: 'Domain not found.', response_body: body)
      expect(err.response_body).to eq(body)
    end

    it 'defaults response_body to nil' do
      expect(error.response_body).to be_nil
    end
  end

  describe Lettermint::AuthenticationError do
    subject(:error) { described_class.new(message: 'Unauthorized', status_code: 401) }

    it 'inherits from HttpRequestError' do
      expect(error).to be_a(Lettermint::HttpRequestError)
    end

    it 'exposes the status code' do
      expect(error.status_code).to eq(401)
    end

    it 'works for 403' do
      err = described_class.new(message: 'Forbidden', status_code: 403)
      expect(err.status_code).to eq(403)
    end

    it 'exposes code and details' do
      err = described_class.new(message: 'Unauthorized', status_code: 401, code: 'UNAUTHENTICATED', details: nil)
      expect(err.code).to eq('UNAUTHENTICATED')
      expect(err.details).to be_nil
    end

    it 'defaults code and details to nil' do
      expect(error.code).to be_nil
      expect(error.details).to be_nil
    end
  end

  describe Lettermint::RateLimitError do
    subject(:error) { described_class.new(message: 'Rate limit exceeded', retry_after: 60) }

    it 'inherits from HttpRequestError' do
      expect(error).to be_a(Lettermint::HttpRequestError)
    end

    it 'hardcodes status_code to 429' do
      expect(error.status_code).to eq(429)
    end

    it 'exposes retry_after' do
      expect(error.retry_after).to eq(60)
    end

    it 'defaults retry_after to nil' do
      err = described_class.new(message: 'Rate limit exceeded')
      expect(err.retry_after).to be_nil
    end

    it 'exposes code and details' do
      err = described_class.new(message: 'Rate limit exceeded', code: 'RATE_LIMITED', details: { 'limit' => 100 })
      expect(err.code).to eq('RATE_LIMITED')
      expect(err.details).to eq({ 'limit' => 100 })
    end

    it 'defaults code and details to nil' do
      expect(error.code).to be_nil
      expect(error.details).to be_nil
    end
  end

  describe Lettermint::ErrorBody do
    describe '.parse' do
      it 'extracts message and code from an ApiError body with no details key' do
        body = JSON.parse(fixture('errors/not_found_api_error.json'))
        expect(described_class.parse(404, body)).to eq(['Resource not found.', 'RESOURCE_NOT_FOUND', nil])
      end

      it 'passes ApiError details through untouched' do
        body = { 'error' => { 'code' => 'VALIDATION_FAILED', 'message' => 'Bad', 'details' => { 'to' => ['x'] } } }
        expect(described_class.parse(422, body)).to eq(['Bad', 'VALIDATION_FAILED', { 'to' => ['x'] }])
      end

      it 'treats a String error as a code and falls back to HTTP <status> for the message' do
        body = JSON.parse(fixture('errors/not_found_string_error.json'))
        expect(described_class.parse(404, body)).to eq(['HTTP 404', 'not_found', nil])
      end

      it 'uses the top-level message from a router 404 ErrorMessage body' do
        body = JSON.parse(fixture('errors/not_found_error_message.json'))
        expected = ['The route v1/this-route-does-not-exist could not be found.', nil, nil]
        expect(described_class.parse(404, body)).to eq(expected)
      end

      it 'falls back to HTTP <status> for a blank ErrorMessage body' do
        body = JSON.parse(fixture('errors/unauthorized_empty_message.json'))
        expect(described_class.parse(401, body)).to eq(['HTTP 401', nil, nil])
      end

      it 'prefers the ApiError message over a top-level message' do
        body = { 'error' => { 'code' => 'X', 'message' => 'Inner' }, 'message' => 'Outer' }
        expect(described_class.parse(400, body)).to eq(['Inner', 'X', nil])
      end

      it 'returns HTTP <status> with no code or details for a String body' do
        expect(described_class.parse(500, 'Internal Server Error')).to eq(['HTTP 500', nil, nil])
      end

      it 'returns HTTP <status> with no code or details for a nil body' do
        expect(described_class.parse(502, nil)).to eq(['HTTP 502', nil, nil])
      end

      it 'returns HTTP <status> with no code or details for an Array body' do
        expect(described_class.parse(500, ['unexpected'])).to eq(['HTTP 500', nil, nil])
      end

      it 'ignores non-String code and message values inside error' do
        body = { 'error' => { 'code' => 123, 'message' => ['not a string'] } }
        expect(described_class.parse(400, body)).to eq(['HTTP 400', nil, nil])
      end

      it 'ignores a non-String top-level message' do
        body = { 'message' => { 'text' => 'nested' } }
        expect(described_class.parse(400, body)).to eq(['HTTP 400', nil, nil])
      end

      it 'falls through to the top-level message when the ApiError message is blank' do
        body = { 'error' => { 'code' => 'X', 'message' => '   ' }, 'message' => 'Top level' }
        expect(described_class.parse(400, body)).to eq(['Top level', 'X', nil])
      end

      it 'falls back to HTTP <status> when every message is blank' do
        body = { 'error' => { 'code' => 'X', 'message' => '' }, 'message' => '' }
        expect(described_class.parse(400, body)).to eq(['HTTP 400', 'X', nil])
      end
    end
  end

  describe Lettermint::TimeoutError do
    it 'inherits from Lettermint::Error' do
      expect(described_class.new('timeout')).to be_a(Lettermint::Error)
    end
  end

  describe Lettermint::ConnectionError do
    it 'inherits from Lettermint::Error' do
      expect(described_class.new(message: 'connection failed')).to be_a(Lettermint::Error)
    end

    it 'exposes original_exception' do
      original = Faraday::ConnectionFailed.new('refused')
      err = described_class.new(message: 'connection failed', original_exception: original)
      expect(err.original_exception).to eq(original)
    end

    it 'defaults original_exception to nil' do
      err = described_class.new(message: 'connection failed')
      expect(err.original_exception).to be_nil
    end
  end

  describe Lettermint::WebhookVerificationError do
    it 'inherits from Lettermint::Error' do
      expect(described_class.new('verify')).to be_a(Lettermint::Error)
    end
  end

  describe Lettermint::InvalidSignatureError do
    it 'inherits from WebhookVerificationError' do
      expect(described_class.new('bad sig')).to be_a(Lettermint::WebhookVerificationError)
    end
  end

  describe Lettermint::TimestampToleranceError do
    it 'inherits from WebhookVerificationError' do
      expect(described_class.new('stale')).to be_a(Lettermint::WebhookVerificationError)
    end
  end

  describe Lettermint::WebhookJsonDecodeError do
    it 'inherits from WebhookVerificationError' do
      expect(described_class.new('parse error')).to be_a(Lettermint::WebhookVerificationError)
    end

    it 'exposes original_exception' do
      original = JSON::ParserError.new('unexpected token')
      err = described_class.new('parse error', original_exception: original)
      expect(err.original_exception).to eq(original)
    end
  end

  describe 'pattern matching on errors' do
    it 'matches ValidationError with rescue' do
      expect do
        raise Lettermint::ValidationError.new(message: 'bad', error_type: 'invalid')
      end.to raise_error(Lettermint::HttpRequestError)
    end

    it 'matches ClientError with rescue' do
      expect do
        raise Lettermint::ClientError.new(message: 'bad')
      end.to raise_error(Lettermint::HttpRequestError)
    end

    it 'matches NotFoundError with rescue' do
      expect do
        raise Lettermint::NotFoundError.new(message: 'missing')
      end.to raise_error(Lettermint::HttpRequestError)
    end
  end
end
