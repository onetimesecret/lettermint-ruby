# frozen_string_literal: true

require 'faraday'

module Lettermint
  class HttpClient
    def initialize(api_token:, base_url:, timeout:, auth_scheme: :project)
      normalized_url = "#{base_url.chomp('/')}/"
      @connection = Faraday.new(url: normalized_url) do |f|
        f.request :json
        f.response :json
        f.options.timeout = timeout
        f.options.open_timeout = timeout
        f.headers = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          **auth_headers(api_token, auth_scheme),
          'User-Agent' => "Lettermint/#{Lettermint::VERSION} (Ruby; ruby #{RUBY_VERSION})"
        }
      end
    end

    def get(path:, params: nil, headers: nil)
      with_error_handling do
        @connection.get(path.delete_prefix('/')) do |req|
          req.params = params if params
          req.headers.update(headers) if headers
        end
      end
    end

    def post(path:, data: nil, headers: nil)
      with_error_handling do
        @connection.post(path.delete_prefix('/')) do |req|
          req.body = data if data
          req.headers.update(headers) if headers
        end
      end
    end

    def put(path:, data: nil, headers: nil)
      with_error_handling do
        @connection.put(path.delete_prefix('/')) do |req|
          req.body = data if data
          req.headers.update(headers) if headers
        end
      end
    end

    def delete(path:, headers: nil)
      with_error_handling do
        @connection.delete(path.delete_prefix('/')) do |req|
          req.headers.update(headers) if headers
        end
      end
    end

    private

    def auth_headers(token, scheme)
      case scheme.to_sym
      when :project then { 'x-lettermint-token' => token }
      when :team    then { 'Authorization' => "Bearer #{token}" }
      else raise ArgumentError, "Unknown auth_scheme: #{scheme}"
      end
    end

    def with_error_handling
      response = yield
      handle_response(response)
    rescue Faraday::TimeoutError, Timeout::Error
      raise Lettermint::TimeoutError, "Request timeout after #{@connection.options.timeout}s"
    rescue Faraday::SSLError => e
      raise Lettermint::ConnectionError.new(message: "SSL error: #{e.message}", original_exception: e)
    rescue Faraday::ConnectionFailed => e
      raise Lettermint::ConnectionError.new(message: e.message, original_exception: e)
    rescue Faraday::ParsingError => e
      raise Lettermint::ResponseParsingError.new(message: "API response parsing failed: #{e.message}",
                                                 original_exception: e)
    end

    def handle_response(response)
      return response.body if response.success?

      raise build_error(response.status, normalize_body(response.body), response.headers)
    end

    # Hash stays Hash; String is stripped (nil when empty); anything else passes through as parsed.
    def normalize_body(body)
      return body unless body.is_a?(String)

      stripped = body.strip
      stripped.empty? ? nil : stripped
    end

    def build_error(status, body, headers)
      message, code, details = ErrorBody.parse(status, body)
      common = { message: message, response_body: body, code: code, details: details }

      case status
      when 401, 403 then AuthenticationError.new(status_code: status, **common)
      when 400 then ClientError.new(**common)
      when 404 then NotFoundError.new(**common)
      when 422 then ValidationError.new(error_type: validation_error_type(body, code), **common)
      when 429 then RateLimitError.new(retry_after: retry_after_from(headers), **common)
      else HttpRequestError.new(status_code: status, **common)
      end
    end

    # A String `error` is kept verbatim; a Hash `error` contributes its code.
    def validation_error_type(body, code)
      error = body.is_a?(Hash) ? body['error'] : nil
      return error if error.is_a?(String)

      code || 'ValidationError'
    end

    def retry_after_from(headers)
      value = headers && headers['Retry-After']
      value && Integer(value, exception: false)
    end
  end
end
