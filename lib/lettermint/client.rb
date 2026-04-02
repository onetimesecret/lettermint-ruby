# frozen_string_literal: true

module Lettermint
  class Client
    attr_reader :configuration

    def initialize(api_token:, base_url: nil, timeout: nil)
      validate_api_token!(api_token)

      @configuration = Configuration.new
      @configuration.base_url = base_url || Lettermint.configuration.base_url
      @configuration.timeout = timeout || Lettermint.configuration.timeout

      yield @configuration if block_given?

      @http_client = HttpClient.new(
        api_token: api_token,
        base_url: @configuration.base_url,
        timeout: @configuration.timeout
      )
    end

    def email
      EmailMessage.new(http_client: @http_client)
    end

    # Makes a GET request to an arbitrary API endpoint.
    #
    # @param path [String] The API endpoint path (e.g., '/domains')
    # @param params [Hash, nil] Query parameters to include in the request
    # @param headers [Hash, nil] Additional HTTP headers
    # @return [Hash] The parsed JSON response body
    def get(path, params: nil, headers: nil)
      @http_client.get(path: path, params: params, headers: headers)
    end

    # Makes a POST request to an arbitrary API endpoint.
    #
    # @param path [String] The API endpoint path
    # @param data [Hash, nil] The request body (will be JSON-encoded)
    # @param headers [Hash, nil] Additional HTTP headers
    # @return [Hash] The parsed JSON response body
    def post(path, data: nil, headers: nil)
      @http_client.post(path: path, data: data, headers: headers)
    end

    # Makes a PUT request to an arbitrary API endpoint.
    #
    # @param path [String] The API endpoint path
    # @param data [Hash, nil] The request body (will be JSON-encoded)
    # @param headers [Hash, nil] Additional HTTP headers
    # @return [Hash] The parsed JSON response body
    def put(path, data: nil, headers: nil)
      @http_client.put(path: path, data: data, headers: headers)
    end

    # Makes a DELETE request to an arbitrary API endpoint.
    #
    # @param path [String] The API endpoint path
    # @param headers [Hash, nil] Additional HTTP headers
    # @return [Hash] The parsed JSON response body
    def delete(path, headers: nil)
      @http_client.delete(path: path, headers: headers)
    end

    private

    def validate_api_token!(token)
      raise ArgumentError, 'API token cannot be empty' if token.nil? || token.to_s.strip.empty?
    end
  end
end
