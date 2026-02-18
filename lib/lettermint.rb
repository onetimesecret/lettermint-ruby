# frozen_string_literal: true

require_relative 'lettermint/version'
require_relative 'lettermint/errors'
require_relative 'lettermint/types'
require_relative 'lettermint/configuration'
require_relative 'lettermint/http_client'
require_relative 'lettermint/email_message'
require_relative 'lettermint/webhook'
require_relative 'lettermint/client'

module Lettermint
  class << self
    def configure
      yield configuration if block_given?
      configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset_configuration!
      @configuration = nil
    end
  end
end
