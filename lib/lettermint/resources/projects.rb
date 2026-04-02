# frozen_string_literal: true

module Lettermint
  module Resources
    # Projects resource for managing projects, members, and accessing routes.
    class Projects < Base
      # List all projects.
      # @param page_size [Integer, nil] Number of items per page (default: 30)
      # @param page_cursor [String, nil] Cursor for pagination
      # @param sort [String, nil] Sort field: name, created_at (prefix - for desc)
      # @param search [String, nil] Search filter
      # @return [Hash] Paginated list of projects
      def list(page_size: nil, page_cursor: nil, sort: nil, search: nil)
        params = build_params(page_size: page_size, page_cursor: page_cursor, sort: sort, search: search)
        @http_client.get(path: '/projects', params: params)
      end

      # Create a new project.
      # @param name [String] Project name (max 255 chars)
      # @param smtp_enabled [Boolean, nil] Enable SMTP (default: false)
      # @param initial_routes [String, nil] Initial routes: both, transactional, broadcast (default: both)
      # @return [Hash] Created project data including api_token
      def create(name:, smtp_enabled: nil, initial_routes: nil)
        data = { name: name }
        data[:smtp_enabled] = smtp_enabled unless smtp_enabled.nil?
        data[:initial_routes] = initial_routes if initial_routes
        @http_client.post(path: '/projects', data: data)
      end

      # Get project details.
      # @param id [String] Project ID
      # @param include [String, nil] Related data: routes, domains, teamMembers, messageStats (+ Count/Exists variants)
      # @return [Hash] Project data with optional includes
      def find(id, include: nil)
        params = include ? { 'include' => include } : nil
        @http_client.get(path: "/projects/#{id}", params: params)
      end

      # Update a project.
      # @param id [String] Project ID
      # @param name [String, nil] New project name
      # @param smtp_enabled [Boolean, nil] Enable/disable SMTP
      # @param default_route_id [String, nil] Default route UUID
      # @return [Hash] Updated project data
      def update(id, name: nil, smtp_enabled: nil, default_route_id: nil)
        data = {}
        data[:name] = name if name
        data[:smtp_enabled] = smtp_enabled unless smtp_enabled.nil?
        data[:default_route_id] = default_route_id if default_route_id
        @http_client.put(path: "/projects/#{id}", data: data)
      end

      # Delete a project.
      # @param id [String] Project ID
      # @return [Hash] Confirmation message
      def delete(id)
        @http_client.delete(path: "/projects/#{id}")
      end

      # Rotate the project API token.
      # @param id [String] Project ID
      # @return [Hash] Contains new_token
      def rotate_token(id)
        @http_client.post(path: "/projects/#{id}/rotate-token")
      end

      # Update project members (replace all).
      # @param id [String] Project ID
      # @param team_member_ids [Array<String>] Array of team member IDs
      # @return [Hash] Confirmation
      def update_members(id, team_member_ids:)
        @http_client.put(path: "/projects/#{id}/members", data: { team_member_ids: team_member_ids })
      end

      # Add a member to the project.
      # @param project_id [String] Project ID
      # @param member_id [String] Team member ID
      # @return [Hash] Confirmation
      def add_member(project_id, member_id)
        @http_client.post(path: "/projects/#{project_id}/members/#{member_id}")
      end

      # Remove a member from the project.
      # @param project_id [String] Project ID
      # @param member_id [String] Team member ID
      # @return [Hash] Confirmation
      def remove_member(project_id, member_id)
        @http_client.delete(path: "/projects/#{project_id}/members/#{member_id}")
      end

      # Get a routes accessor scoped to this project.
      # @param project_id [String] Project ID
      # @return [Routes] Routes resource scoped to the project
      def routes(project_id)
        Routes.new(http_client: @http_client, project_id: project_id)
      end
    end
  end
end
