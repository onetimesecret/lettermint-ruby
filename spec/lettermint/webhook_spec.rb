# frozen_string_literal: true

require 'spec_helper'
require 'openssl'

RSpec.describe Lettermint::Webhook do
  let(:secret) { 'whsec_test_secret_key' }
  let(:payload) { '{"event":"email.delivered","data":{"message_id":"msg_123"}}' }
  let(:timestamp) { Time.now.to_i }

  let(:signature_hash) do
    signed_content = "#{timestamp}.#{payload}"
    OpenSSL::HMAC.hexdigest('SHA256', secret, signed_content)
  end

  let(:signature_header) { "t=#{timestamp},v1=#{signature_hash}" }

  subject(:webhook) { described_class.new(secret: secret) }

  describe '#initialize' do
    it 'raises ArgumentError for empty secret' do
      expect { described_class.new(secret: '') }.to raise_error(ArgumentError, /cannot be empty/)
    end

    it 'raises ArgumentError for nil secret' do
      expect { described_class.new(secret: nil) }.to raise_error(ArgumentError, /cannot be empty/)
    end
  end

  describe '#verify' do
    it 'returns parsed payload for valid signature' do
      result = webhook.verify(payload, signature_header)
      expect(result).to eq(JSON.parse(payload))
    end

    it 'raises InvalidSignatureError for wrong secret' do
      bad_webhook = described_class.new(secret: 'wrong_secret')

      expect { bad_webhook.verify(payload, signature_header) }
        .to raise_error(Lettermint::InvalidSignatureError)
    end

    it 'raises InvalidSignatureError for tampered payload' do
      tampered = '{"event":"email.delivered","data":{"message_id":"msg_HACKED"}}'

      expect { webhook.verify(tampered, signature_header) }
        .to raise_error(Lettermint::InvalidSignatureError)
    end

    it 'raises WebhookVerificationError for invalid signature format' do
      expect { webhook.verify(payload, 'garbage') }
        .to raise_error(Lettermint::WebhookVerificationError, /Invalid signature format/)
    end

    it 'raises WebhookVerificationError for nil signature' do
      expect { webhook.verify(payload, nil) }
        .to raise_error(Lettermint::WebhookVerificationError, /Invalid signature format/)
    end

    it 'raises TimestampToleranceError for old timestamp' do
      old_ts = Time.now.to_i - 600
      old_content = "#{old_ts}.#{payload}"
      old_hash = OpenSSL::HMAC.hexdigest('SHA256', secret, old_content)
      old_sig = "t=#{old_ts},v1=#{old_hash}"

      expect { webhook.verify(payload, old_sig) }
        .to raise_error(Lettermint::TimestampToleranceError, /too old or too far in the future/)
    end

    it 'raises TimestampToleranceError for future timestamp' do
      future_ts = Time.now.to_i + 600
      future_content = "#{future_ts}.#{payload}"
      future_hash = OpenSSL::HMAC.hexdigest('SHA256', secret, future_content)
      future_sig = "t=#{future_ts},v1=#{future_hash}"

      expect { webhook.verify(payload, future_sig) }
        .to raise_error(Lettermint::TimestampToleranceError)
    end

    it 'accepts timestamp within tolerance' do
      recent_ts = Time.now.to_i - 100
      recent_content = "#{recent_ts}.#{payload}"
      recent_hash = OpenSSL::HMAC.hexdigest('SHA256', secret, recent_content)
      recent_sig = "t=#{recent_ts},v1=#{recent_hash}"

      result = webhook.verify(payload, recent_sig)
      expect(result).to eq(JSON.parse(payload))
    end

    it 'validates cross-referenced timestamp' do
      expect { webhook.verify(payload, signature_header, timestamp: timestamp + 1) }
        .to raise_error(Lettermint::WebhookVerificationError, /Timestamp mismatch between header and signature/)
    end

    it 'accepts matching cross-referenced timestamp' do
      result = webhook.verify(payload, signature_header, timestamp: timestamp)
      expect(result).to eq(JSON.parse(payload))
    end

    it 'raises WebhookJsonDecodeError for invalid JSON payload' do
      bad_payload = 'not json'
      bad_content = "#{timestamp}.#{bad_payload}"
      bad_hash = OpenSSL::HMAC.hexdigest('SHA256', secret, bad_content)
      bad_sig = "t=#{timestamp},v1=#{bad_hash}"

      expect { webhook.verify(bad_payload, bad_sig) }
        .to raise_error(Lettermint::WebhookJsonDecodeError) { |e|
          expect(e.original_exception).to be_a(JSON::ParserError)
        }
    end

    it 'uses custom tolerance' do
      lax_webhook = described_class.new(secret: secret, tolerance: 1000)
      old_ts = Time.now.to_i - 800
      old_content = "#{old_ts}.#{payload}"
      old_hash = OpenSSL::HMAC.hexdigest('SHA256', secret, old_content)
      old_sig = "t=#{old_ts},v1=#{old_hash}"

      result = lax_webhook.verify(payload, old_sig)
      expect(result).to eq(JSON.parse(payload))
    end
  end

  describe '#verify_headers' do
    it 'verifies from headers hash' do
      headers = {
        'X-Lettermint-Signature' => signature_header,
        'X-Lettermint-Delivery' => timestamp.to_s
      }

      result = webhook.verify_headers(headers, payload)
      expect(result).to eq(JSON.parse(payload))
    end

    it 'handles case-insensitive headers' do
      headers = {
        'x-lettermint-signature' => signature_header,
        'x-lettermint-delivery' => timestamp.to_s
      }

      result = webhook.verify_headers(headers, payload)
      expect(result).to eq(JSON.parse(payload))
    end

    it 'raises when signature header is missing' do
      headers = { 'X-Lettermint-Delivery' => timestamp.to_s }

      expect { webhook.verify_headers(headers, payload) }
        .to raise_error(Lettermint::WebhookVerificationError, /Missing/)
    end

    it 'raises when delivery header is missing' do
      headers = { 'X-Lettermint-Signature' => signature_header }

      expect { webhook.verify_headers(headers, payload) }
        .to raise_error(Lettermint::WebhookVerificationError, /Missing/)
    end

    it 'raises for non-integer delivery header' do
      headers = {
        'X-Lettermint-Signature' => signature_header,
        'X-Lettermint-Delivery' => 'not-a-number'
      }

      expect { webhook.verify_headers(headers, payload) }
        .to raise_error(Lettermint::WebhookVerificationError, /Invalid/)
    end

    it 'raises for non-string delivery header (e.g. Array from Rack)' do
      headers = {
        'X-Lettermint-Signature' => signature_header,
        'X-Lettermint-Delivery' => [timestamp.to_s]
      }

      expect { webhook.verify_headers(headers, payload) }
        .to raise_error(Lettermint::WebhookVerificationError, /Invalid/)
    end
  end

  describe '.verify_signature' do
    it 'provides a static convenience method' do
      result = described_class.verify_signature(payload, signature_header, secret: secret)
      expect(result).to eq(JSON.parse(payload))
    end

    it 'passes tolerance through' do
      old_ts = Time.now.to_i - 400
      old_content = "#{old_ts}.#{payload}"
      old_hash = OpenSSL::HMAC.hexdigest('SHA256', secret, old_content)
      old_sig = "t=#{old_ts},v1=#{old_hash}"

      expect { described_class.verify_signature(payload, old_sig, secret: secret, tolerance: 100) }
        .to raise_error(Lettermint::TimestampToleranceError)
    end
  end
end
