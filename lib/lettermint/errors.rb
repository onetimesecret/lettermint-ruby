# frozen_string_literal: true

module Lettermint
  class Error < StandardError; end

  class HttpRequestError < Error
    attr_reader :status_code, :response_body

    def initialize(message:, status_code:, response_body: nil)
      @status_code = status_code
      @response_body = response_body
      super(message)
    end
  end

  class ValidationError < HttpRequestError
    attr_reader :error_type

    def initialize(message:, error_type:, response_body: nil)
      @error_type = error_type
      super(message: message, status_code: 422, response_body: response_body)
    end
  end

  class ClientError < HttpRequestError
    def initialize(message:, response_body: nil)
      super(message: message, status_code: 400, response_body: response_body)
    end
  end

  class AuthenticationError < HttpRequestError
    def initialize(message:, status_code:, response_body: nil)
      super
    end
  end

  class RateLimitError < HttpRequestError
    attr_reader :retry_after

    def initialize(message:, retry_after: nil, response_body: nil)
      @retry_after = retry_after
      super(message: message, status_code: 429, response_body: response_body)
    end
  end

  class TimeoutError < Error; end

  class WebhookVerificationError < Error; end

  class InvalidSignatureError < WebhookVerificationError; end

  class TimestampToleranceError < WebhookVerificationError; end

  class WebhookJsonDecodeError < WebhookVerificationError
    attr_reader :original_exception

    def initialize(message, original_exception: nil)
      @original_exception = original_exception
      super(message)
    end
  end
end
