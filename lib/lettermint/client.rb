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

    private

    def validate_api_token!(token)
      raise ArgumentError, 'API token cannot be empty' if token.nil? || token.to_s.strip.empty?
    end
  end
end
