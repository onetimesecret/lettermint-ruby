# frozen_string_literal: true

require 'faraday'

module Lettermint
  class HttpClient
    def initialize(api_token:, base_url:, timeout:)
      normalized_url = "#{base_url.chomp('/')}/"
      @connection = Faraday.new(url: normalized_url) do |f|
        f.request :json
        f.response :json
        f.options.timeout = timeout
        f.options.open_timeout = timeout
        f.headers = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
          'x-lettermint-token' => api_token,
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

    def with_error_handling
      response = yield
      handle_response(response)
    rescue Faraday::TimeoutError, Timeout::Error
      raise Lettermint::TimeoutError, "Request timeout after #{@connection.options.timeout}s"
    rescue Faraday::ConnectionFailed => e
      raise Lettermint::Error, e.message
    end

    def handle_response(response)
      return response.body if response.success?

      body = response.body.is_a?(Hash) ? response.body : nil
      raise_api_error(response.status, body)
    end

    def raise_api_error(status, body)
      case status
      when 422
        raise ValidationError.new(
          message: body_field(body, 'message', 'Validation error'),
          error_type: body_field(body, 'error', 'ValidationError'),
          response_body: body
        )
      when 400
        raise ClientError.new(message: body_field(body, 'error', 'Unknown client error'), response_body: body)
      else
        raise HttpRequestError.new(
          message: body_field(body, 'message', "HTTP #{status}"),
          status_code: status, response_body: body
        )
      end
    end

    def body_field(body, key, default)
      body&.dig(key) || default
    end
  end
end
