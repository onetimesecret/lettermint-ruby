# frozen_string_literal: true

require 'time'

module Lettermint
  class Error < StandardError; end

  class HttpRequestError < Error
    # code: the API error code string, when the response carried one.
    # details: Hash, Array or nil; the shape depends on code.
    attr_reader :status_code, :response_body, :code, :details

    def initialize(message:, status_code:, response_body: nil, code: nil, details: nil)
      @status_code = status_code
      @response_body = response_body
      @code = code
      @details = details
      super(message)
    end
  end

  class ValidationError < HttpRequestError
    attr_reader :error_type

    def initialize(message:, error_type:, response_body: nil, code: nil, details: nil)
      @error_type = error_type
      super(message: message, status_code: 422, response_body: response_body, code: code, details: details)
    end

    # Field errors ({"field" => ["message", ...]}) from a Hash `errors` in the body; nil otherwise.
    def errors
      value = response_body['errors'] if response_body.is_a?(Hash)
      value.is_a?(Hash) ? value : nil
    end
  end

  class ClientError < HttpRequestError
    def initialize(message:, response_body: nil, code: nil, details: nil)
      super(message: message, status_code: 400, response_body: response_body, code: code, details: details)
    end
  end

  class NotFoundError < HttpRequestError
    def initialize(message:, response_body: nil, code: nil, details: nil)
      super(message: message, status_code: 404, response_body: response_body, code: code, details: details)
    end
  end

  class AuthenticationError < HttpRequestError
    def initialize(message:, status_code:, response_body: nil, code: nil, details: nil)
      super
    end
  end

  class RateLimitError < HttpRequestError
    attr_reader :retry_after

    def initialize(message:, retry_after: nil, response_body: nil, code: nil, details: nil)
      @retry_after = retry_after
      super(message: message, status_code: 429, response_body: response_body, code: code, details: details)
    end
  end

  class ConflictError < HttpRequestError
    def initialize(message:, response_body: nil, code: nil, details: nil)
      super(message: message, status_code: 409, response_body: response_body, code: code, details: details)
    end
  end

  # Raised on 500-599; status_code is the actual status.
  class ServerError < HttpRequestError
    attr_reader :retry_after

    # rubocop:disable-next Metrics/ParameterLists
    def initialize(message:, status_code:, retry_after: nil, response_body: nil, code: nil, details: nil)
      @retry_after = retry_after
      super(message: message, status_code: status_code, response_body: response_body, code: code, details: details)
    end
  end

  # Extracts [message, code, details] from an error response body, mirroring the
  # official Node and Python SDKs. Only a Hash body is inspected; any other body
  # yields "HTTP <status>" with no code or details.
  # @api private
  module ErrorBody
    module_function

    def parse(status, body)
      message, code, details = body.is_a?(Hash) ? fields_from(body) : []
      message = "HTTP #{status}" if blank?(message)
      [message, code, details]
    end

    def fields_from(body)
      error = body['error']
      message, code, details = fields_from_error(error)
      message = body['message'] if blank?(message) && body['message'].is_a?(String)
      [message, code, details]
    end

    # A String `error` is a code, never a message.
    def fields_from_error(error)
      case error
      when Hash then [string_or_nil(error['message']), string_or_nil(error['code']), error['details']]
      when String then [nil, error, nil]
      else []
      end
    end

    def string_or_nil(value)
      value.is_a?(String) ? value : nil
    end

    def blank?(value)
      value.nil? || value.strip.empty?
    end
  end

  # Converts a Retry-After header value to seconds: delay-seconds as given, an
  # HTTP-date as whole seconds from now (floored at 0), anything else nil.
  # @api private
  module RetryAfter
    module_function

    def parse(value)
      return unless value.is_a?(String)

      Integer(value, exception: false) || seconds_until(value)
    end

    def seconds_until(http_date)
      [(Time.httpdate(http_date) - Time.now).ceil, 0].max
    rescue ArgumentError
      nil
    end
  end

  class TimeoutError < Error; end

  class ConnectionError < Error
    attr_reader :original_exception

    def initialize(message:, original_exception: nil)
      @original_exception = original_exception
      super(message)
    end
  end

  class ResponseParsingError < Error
    attr_reader :original_exception

    def initialize(message:, original_exception: nil)
      @original_exception = original_exception
      super(message)
    end
  end

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
