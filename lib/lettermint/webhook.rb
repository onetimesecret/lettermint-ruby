# frozen_string_literal: true

require 'json'
require 'openssl'

module Lettermint
  class Webhook
    DEFAULT_TOLERANCE = 300

    SIGNATURE_HEADER = 'x-lettermint-signature'
    DELIVERY_HEADER = 'x-lettermint-delivery'

    def initialize(secret:, tolerance: DEFAULT_TOLERANCE)
      raise ArgumentError, 'Webhook secret cannot be empty' if secret.nil? || secret.empty?

      @secret = secret
      @tolerance = tolerance
    end

    def verify(payload, signature, timestamp: nil)
      ts, sig_hash = parse_signature(signature)

      if timestamp && timestamp != ts
        raise WebhookVerificationError, "Timestamp mismatch: header=#{timestamp}, signature=#{ts}"
      end

      validate_timestamp(ts)
      validate_signature(payload, ts, sig_hash)
      parse_payload(payload)
    end

    def verify_headers(headers, payload)
      normalized = headers.transform_keys(&:downcase)

      signature = normalized[SIGNATURE_HEADER]
      delivery = normalized[DELIVERY_HEADER]

      raise WebhookVerificationError, "Missing #{SIGNATURE_HEADER} header" unless signature
      raise WebhookVerificationError, "Missing #{DELIVERY_HEADER} header" unless delivery

      ts = begin
        Integer(delivery)
      rescue ArgumentError
        raise WebhookVerificationError, "Invalid #{DELIVERY_HEADER} header: #{delivery}"
      end

      verify(payload, signature, timestamp: ts)
    end

    def self.verify_signature(payload, signature, secret:, timestamp: nil, tolerance: DEFAULT_TOLERANCE)
      new(secret: secret, tolerance: tolerance).verify(payload, signature, timestamp: timestamp)
    end

    private

    def parse_signature(signature)
      parts = signature.split(',').each_with_object({}) do |part, hash|
        key, value = part.split('=', 2)
        hash[key.strip] = value&.strip if key && value
      end

      sig_ts = Integer(parts['t'])
      sig_hash = parts['v1']
      raise WebhookVerificationError, 'Invalid signature format' unless sig_hash

      [sig_ts, sig_hash]
    rescue ArgumentError, TypeError
      raise WebhookVerificationError, 'Invalid signature format'
    end

    def validate_timestamp(sig_ts)
      difference = (Time.now.to_i - sig_ts).abs
      return if difference <= @tolerance

      raise TimestampToleranceError,
            "Timestamp #{sig_ts} is outside tolerance of #{@tolerance}s (difference: #{difference}s)"
    end

    def validate_signature(payload, sig_ts, expected_hash)
      signed_content = "#{sig_ts}.#{payload}"
      computed = OpenSSL::HMAC.hexdigest('SHA256', @secret, signed_content)

      return if OpenSSL.secure_compare(computed, expected_hash)

      raise InvalidSignatureError, 'Signature verification failed'
    end

    def parse_payload(payload)
      JSON.parse(payload)
    rescue JSON::ParserError => e
      raise WebhookJsonDecodeError.new('Failed to parse webhook payload as JSON', original_exception: e)
    end
  end
end
