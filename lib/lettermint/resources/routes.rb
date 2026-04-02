# frozen_string_literal: true

module Lettermint
  module Resources
    # Routes resource for managing project routes (transactional, broadcast, inbound).
    # Can be instantiated with a project_id for scoped operations or without for direct route access.
    class Routes < Base
      # @param http_client [HttpClient] HTTP client instance
      # @param project_id [String, nil] Optional project ID for scoped operations
      def initialize(http_client:, project_id: nil)
        super(http_client: http_client)
        @project_id = project_id
      end

      # List routes for a project.
      # Requires project_id to be set (via constructor or projects.routes(id)).
      # @param page_size [Integer, nil] Number of items per page (default: 30)
      # @param page_cursor [String, nil] Cursor for pagination
      # @param sort [String, nil] Sort field: name, slug, created_at (prefix - for desc)
      # @param route_type [String, nil] Filter: transactional, broadcast, inbound
      # @param is_default [Boolean, nil] Filter by default route status
      # @param search [String, nil] Search filter
      # @return [Hash] Paginated list of routes
      # rubocop:disable Metrics/ParameterLists
      def list(page_size: nil, page_cursor: nil, sort: nil, route_type: nil,
               is_default: nil, search: nil)
        raise ArgumentError, 'project_id required for listing routes' unless @project_id

        params = build_params(
          page_size: page_size,
          page_cursor: page_cursor,
          sort: sort,
          route_type: route_type,
          is_default: is_default,
          search: search
        )
        @http_client.get(path: "/projects/#{@project_id}/routes", params: params)
      end
      # rubocop:enable Metrics/ParameterLists

      # Create a new route in a project.
      # Requires project_id to be set.
      # @param name [String] Route name (max 255 chars)
      # @param route_type [String] Type: transactional, broadcast, inbound
      # @param slug [String, nil] Optional slug (max 255 chars)
      # @return [Hash] Created route data
      def create(name:, route_type:, slug: nil)
        raise ArgumentError, 'project_id required for creating routes' unless @project_id

        data = { name: name, route_type: route_type }
        data[:slug] = slug if slug
        @http_client.post(path: "/projects/#{@project_id}/routes", data: data)
      end

      # Get route details.
      # @param id [String] Route ID
      # @param include [String, nil] Related data: project, statistics
      # @return [Hash] Route data
      def find(id, include: nil)
        params = include ? { 'include' => include } : nil
        @http_client.get(path: "/routes/#{id}", params: params)
      end

      # Update a route.
      # @param id [String] Route ID
      # @param name [String, nil] New route name
      # @param settings [Hash, nil] Route settings (track_opens, track_clicks, disable_hosted_unsubscribe)
      # @param inbound_settings [Hash, nil] Inbound settings (inbound_domain, spam_threshold, etc.)
      # @return [Hash] Updated route data
      def update(id, name: nil, settings: nil, inbound_settings: nil)
        data = {}
        data[:name] = name if name
        data[:settings] = settings if settings
        data[:inbound_settings] = inbound_settings if inbound_settings
        @http_client.put(path: "/routes/#{id}", data: data)
      end

      # Delete a route.
      # @param id [String] Route ID
      # @return [Hash] Confirmation message
      def delete(id)
        @http_client.delete(path: "/routes/#{id}")
      end

      # Verify inbound domain for a route.
      # @param id [String] Route ID
      # @return [Hash] Verification result
      def verify_inbound_domain(id)
        @http_client.post(path: "/routes/#{id}/verify-inbound-domain")
      end
    end
  end
end
