# frozen_string_literal: true

module Lettermint
  class Configuration
    DEFAULT_BASE_URL = 'https://api.lettermint.co/v1'
    DEFAULT_TIMEOUT = 30

    attr_accessor :base_url, :timeout

    def initialize
      @base_url = DEFAULT_BASE_URL
      @timeout = DEFAULT_TIMEOUT
    end
  end
end
