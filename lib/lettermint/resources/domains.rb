# frozen_string_literal: true

module Lettermint
  module Resources
    # Domains resource for managing sending domains and DNS verification.
    class Domains < Base
      # List all domains.
      # @param page_size [Integer, nil] Number of items per page (default: 30)
      # @param page_cursor [String, nil] Cursor for pagination
      # @param sort [String, nil] Sort field: domain, created_at, status_changed_at (prefix - for desc)
      # @param status [String, nil] Filter by status (verified, partially_verified, etc.)
      # @param domain [String, nil] Filter by domain (partial match)
      # @return [Hash] Paginated list of domains
      def list(page_size: nil, page_cursor: nil, sort: nil, status: nil, domain: nil)
        params = build_params(page_size:, page_cursor:, sort:, status:, domain:)
        @http_client.get(path: '/domains', params: params)
      end

      # Create a new domain.
      # @param domain [String] Domain name (max 255 chars)
      # @return [Hash] Created domain data
      def create(domain:)
        @http_client.post(path: '/domains', data: { domain: domain })
      end

      # Get domain details.
      # @param id [String] Domain ID
      # @param include [String, nil] Related data to include (dnsRecords, dnsRecordsCount, dnsRecordsExists)
      # @return [Hash] Domain data with optional includes
      def find(id, include: nil)
        params = build_params(include: include)
        @http_client.get(path: "/domains/#{id}", params: params)
      end

      # Delete a domain.
      # @param id [String] Domain ID
      # @return [Hash] Confirmation message
      def delete(id)
        @http_client.delete(path: "/domains/#{id}")
      end

      # Verify all DNS records for a domain.
      # @param id [String] Domain ID
      # @return [Hash] Verification result
      def verify_dns(id)
        @http_client.post(path: "/domains/#{id}/dns-records/verify")
      end

      # Verify a specific DNS record.
      # @param domain_id [String] Domain ID
      # @param record_id [String] DNS record ID
      # @return [Hash] Verification result
      def verify_dns_record(domain_id, record_id)
        @http_client.post(path: "/domains/#{domain_id}/dns-records/#{record_id}/verify")
      end

      # Update projects associated with a domain.
      # @param id [String] Domain ID
      # @param project_ids [Array<String>] Array of project UUIDs
      # @return [Hash] Updated domain data
      def update_projects(id, project_ids:)
        @http_client.put(path: "/domains/#{id}/projects", data: { project_ids: project_ids })
      end
    end
  end
end
