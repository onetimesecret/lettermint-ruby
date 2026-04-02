# frozen_string_literal: true

module Lettermint
  module Resources
    # Team resource for managing team settings, usage, and members.
    class Team < Base
      # Get team details.
      # @param include [String, nil] Related data to include (features, featuresCount, featuresExists)
      # @return [Hash] Team data
      def get(include: nil)
        params = include ? { 'include' => include } : nil
        @http_client.get(path: '/team', params: params)
      end

      # Update team settings.
      # @param name [String] New team name (max 255 chars)
      # @return [Hash] Updated team data
      def update(name:)
        @http_client.put(path: '/team', data: { name: name })
      end

      # Get team usage statistics.
      # @return [Hash] Current period and up to 12 historical periods
      def usage
        @http_client.get(path: '/team/usage')
      end

      # List team members.
      # @param page_size [Integer, nil] Number of items per page (default: 30)
      # @param page_cursor [String, nil] Cursor for pagination
      # @return [Hash] Paginated list of team members
      def members(page_size: nil, page_cursor: nil)
        params = build_params(page_size: page_size, page_cursor: page_cursor)
        @http_client.get(path: '/team/members', params: params)
      end
    end
  end
end
