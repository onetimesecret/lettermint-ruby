# frozen_string_literal: true

module Lettermint
  module Resources
    # Suppressions resource for managing email suppression lists.
    class Suppressions < Base
      # List suppressions.
      # @param page_size [Integer, nil] Number of items per page (default: 30)
      # @param page_cursor [String, nil] Cursor for pagination
      # @param sort [String, nil] Sort field: value, created_at, reason
      # @param scope [String, nil] Filter: team, project, route
      # @param route_id [String, nil] Filter by route ID
      # @param project_id [String, nil] Filter by project ID
      # @param value [String, nil] Filter by suppression value (email/domain/extension)
      # @param reason [String, nil] Filter: spam_complaint, hard_bounce, unsubscribe, manual
      # @return [Hash] Paginated list of suppressions
      # rubocop:disable Metrics/ParameterLists
      def list(page_size: nil, page_cursor: nil, sort: nil, scope: nil,
               route_id: nil, project_id: nil, value: nil, reason: nil)
        params = build_params(
          page_size: page_size,
          page_cursor: page_cursor,
          sort: sort,
          scope: scope,
          route_id: route_id,
          project_id: project_id,
          value: value,
          reason: reason
        )
        @http_client.get(path: '/suppressions', params: params)
      end
      # rubocop:enable Metrics/ParameterLists

      # Create a suppression entry.
      # @param reason [String] Reason: spam_complaint, hard_bounce, unsubscribe, manual
      # @param scope [String] Scope: team, project, route
      # @param email [String, nil] Single email to suppress (max 255 chars)
      # @param emails [Array<String>, nil] Multiple emails to suppress (max 1000)
      # @param route_id [String, nil] Route ID (required if scope is route)
      # @param project_id [String, nil] Project ID (required if scope is project)
      # @return [Hash] Created suppression data
      def create(reason:, scope:, email: nil, emails: nil, route_id: nil, project_id: nil) # rubocop:disable Metrics/ParameterLists
        data = { reason: reason, scope: scope }
        data[:email] = email if email
        data[:emails] = emails if emails
        data[:route_id] = route_id if route_id
        data[:project_id] = project_id if project_id
        @http_client.post(path: '/suppressions', data: data)
      end

      # Delete a suppression entry.
      # @param id [String] Suppression ID
      # @return [Hash] Confirmation message
      def delete(id)
        @http_client.delete(path: "/suppressions/#{id}")
      end
    end
  end
end
