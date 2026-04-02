# frozen_string_literal: true

module Lettermint
  # Client for the Lettermint Team API (team-level management operations).
  # Authenticates with team tokens (lm_team_*) via Authorization: Bearer header.
  class TeamAPI
    attr_reader :configuration

    def initialize(team_token:, base_url: nil, timeout: nil)
      validate_team_token!(team_token)

      @configuration = Configuration.new
      @configuration.base_url = base_url || Lettermint.configuration.base_url
      @configuration.timeout = timeout || Lettermint.configuration.timeout

      yield @configuration if block_given?

      @http_client = HttpClient.new(
        api_token: team_token,
        base_url: @configuration.base_url,
        timeout: @configuration.timeout,
        auth_scheme: :team
      )
    end

    # Health check endpoint (accepts both token types)
    # @return [Integer] 200 on success
    def ping
      @http_client.get(path: '/ping')
    end

    # Team resource accessor
    # @return [Resources::Team]
    def team
      Resources::Team.new(http_client: @http_client)
    end

    # Domains resource accessor
    # @return [Resources::Domains]
    def domains
      Resources::Domains.new(http_client: @http_client)
    end

    # Projects resource accessor
    # @return [Resources::Projects]
    def projects
      Resources::Projects.new(http_client: @http_client)
    end

    # Webhooks resource accessor
    # @return [Resources::Webhooks]
    def webhooks
      Resources::Webhooks.new(http_client: @http_client)
    end

    # Messages resource accessor
    # @return [Resources::Messages]
    def messages
      Resources::Messages.new(http_client: @http_client)
    end

    # Suppressions resource accessor
    # @return [Resources::Suppressions]
    def suppressions
      Resources::Suppressions.new(http_client: @http_client)
    end

    # Stats resource accessor
    # @return [Resources::Stats]
    def stats
      Resources::Stats.new(http_client: @http_client)
    end

    # Routes resource accessor (top-level for direct route access)
    # For project-scoped routes, use projects.routes(project_id)
    # @return [Resources::Routes]
    def routes
      Resources::Routes.new(http_client: @http_client)
    end

    private

    def validate_team_token!(token)
      raise ArgumentError, 'Team token cannot be empty' if token.nil? || token.to_s.strip.empty?
      return if token.to_s.start_with?('lm_team_')

      raise ArgumentError, "Invalid team token format (expected 'lm_team_*')"
    end
  end
end
