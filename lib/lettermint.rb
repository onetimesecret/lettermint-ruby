# frozen_string_literal: true

require_relative 'lettermint/version'
require_relative 'lettermint/errors'
require_relative 'lettermint/types'
require_relative 'lettermint/configuration'
require_relative 'lettermint/http_client'
require_relative 'lettermint/email_message'
require_relative 'lettermint/webhook'

# Resources (Team API)
require_relative 'lettermint/resources/base'
require_relative 'lettermint/resources/team'
require_relative 'lettermint/resources/domains'
require_relative 'lettermint/resources/projects'
require_relative 'lettermint/resources/routes'
require_relative 'lettermint/resources/webhooks'
require_relative 'lettermint/resources/messages'
require_relative 'lettermint/resources/suppressions'
require_relative 'lettermint/resources/stats'

# API Clients
require_relative 'lettermint/sending_api'
require_relative 'lettermint/team_api'
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
