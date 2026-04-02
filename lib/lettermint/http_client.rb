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
      raise Lettermint::Error, "Failed to parse API response: #{e.message}"
    end

    def handle_response(response)
      return response.body if response.success?

      body = response.body.is_a?(Hash) ? response.body : nil
      raise_api_error(response.status, body, response.headers)
    end

    def raise_api_error(status, body, headers)
      raise build_error(status, body, headers)
    end

    def build_error(status, body, headers) # rubocop:disable Metrics
      msg = ->(key, fallback) { body&.dig(key) || fallback }

      case status
      when 401, 403
        AuthenticationError.new(message: msg['message', "HTTP #{status}"],
                                status_code: status, response_body: body)
      when 400
        ClientError.new(message: msg['error', 'Unknown client error'], response_body: body)
      when 422
        ValidationError.new(message: msg['message', 'Validation error'],
                            error_type: msg['error', 'ValidationError'], response_body: body)
      when 429
        retry_after = headers && headers['Retry-After'] && Integer(headers['Retry-After'], exception: false)
        RateLimitError.new(message: msg['message', 'Rate limit exceeded'],
                           retry_after: retry_after, response_body: body)
      else
        HttpRequestError.new(message: msg['message', "HTTP #{status}"],
                             status_code: status, response_body: body)
      end
    end
  end
end
