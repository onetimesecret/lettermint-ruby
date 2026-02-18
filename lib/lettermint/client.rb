# frozen_string_literal: true

module Lettermint
  class Client
    attr_reader :configuration

    def initialize(api_token:, base_url: nil, timeout: nil)
      @configuration = Configuration.new
      @configuration.base_url = base_url if base_url
      @configuration.timeout = timeout if timeout

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
  end
end
