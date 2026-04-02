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
  end

  describe Lettermint::ClientError do
    subject(:error) { described_class.new(message: 'Bad request') }

    it 'inherits from HttpRequestError' do
      expect(error).to be_a(Lettermint::HttpRequestError)
    end

    it 'hardcodes status_code to 400' do
      expect(error.status_code).to eq(400)
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
  end
end
