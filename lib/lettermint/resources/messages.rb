# frozen_string_literal: true

module Lettermint
  module Resources
    # Messages resource for viewing sent and received messages.
    class Messages < Base
      # List messages.
      # @param page_size [Integer, nil] Number of items per page (default: 30)
      # @param page_cursor [String, nil] Cursor for pagination
      # @param sort [String, nil] Sort field: type, status, from_email, subject, created_at, status_changed_at
      # @param type [String, nil] Filter: inbound, outbound
      # @param status [String, nil] Filter by status
      # @param route_id [String, nil] Filter by route ID
      # @param domain_id [String, nil] Filter by domain ID
      # @param tag [String, nil] Filter by tag
      # @param from_email [String, nil] Filter by sender email
      # @param subject [String, nil] Filter by subject
      # @param from_date [String, nil] Filter from date (Y-m-d)
      # @param to_date [String, nil] Filter to date (Y-m-d)
      # @return [Hash] Paginated list of messages
      # rubocop:disable Metrics/ParameterLists
      def list(page_size: nil, page_cursor: nil, sort: nil, type: nil, status: nil,
               route_id: nil, domain_id: nil, tag: nil, from_email: nil, subject: nil,
               from_date: nil, to_date: nil)
        params = build_params(
          page_size: page_size,
          page_cursor: page_cursor,
          sort: sort,
          type: type,
          status: status,
          route_id: route_id,
          domain_id: domain_id,
          tag: tag,
          from_email: from_email,
          subject: subject,
          from_date: from_date,
          to_date: to_date
        )
        @http_client.get(path: '/messages', params: params)
      end
      # rubocop:enable Metrics/ParameterLists

      # Get message details.
      # @param id [String] Message ID
      # @return [Hash] Message data
      def find(id)
        @http_client.get(path: "/messages/#{id}")
      end

      # Get message events (delivery history).
      # @param id [String] Message ID
      # @param sort [String, nil] Sort field: timestamp, event
      # @return [Hash] List of message events
      def events(id, sort: nil)
        params = sort ? { 'sort' => sort } : nil
        @http_client.get(path: "/messages/#{id}/events", params: params)
      end

      # Get raw message source (RFC822 format).
      # @param id [String] Message ID
      # @return [String] Raw message source (message/rfc822)
      def source(id)
        @http_client.get(path: "/messages/#{id}/source")
      end

      # Get message HTML body.
      # @param id [String] Message ID
      # @return [String] HTML content (text/html)
      def html(id)
        @http_client.get(path: "/messages/#{id}/html")
      end

      # Get message plain text body.
      # @param id [String] Message ID
      # @return [String] Plain text content (text/plain)
      def text(id)
        @http_client.get(path: "/messages/#{id}/text")
      end
    end
  end
end
