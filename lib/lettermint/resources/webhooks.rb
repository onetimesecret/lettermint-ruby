# frozen_string_literal: true

module Lettermint
  module Resources
    # Webhooks resource for managing webhook endpoints and viewing deliveries.
    class Webhooks < Base
      # List all webhooks.
      # @param page_size [Integer, nil] Number of items per page (default: 30)
      # @param page_cursor [String, nil] Cursor for pagination
      # @param sort [String, nil] Sort field: name, url, created_at (prefix - for desc)
      # @param enabled [Boolean, nil] Filter by enabled status
      # @param event [String, nil] Filter by event type
      # @param route_id [String, nil] Filter by route ID
      # @param search [String, nil] Search filter
      # @return [Hash] Paginated list of webhooks
      # rubocop:disable Metrics/ParameterLists
      def list(page_size: nil, page_cursor: nil, sort: nil, enabled: nil,
               event: nil, route_id: nil, search: nil)
        params = build_params(
          page_size: page_size,
          page_cursor: page_cursor,
          sort: sort,
          enabled: enabled,
          event: event,
          route_id: route_id,
          search: search
        )
        @http_client.get(path: '/webhooks', params: params)
      end
      # rubocop:enable Metrics/ParameterLists

      # Create a new webhook.
      # @param route_id [String] Route ID to attach webhook to
      # @param name [String] Webhook name (max 255 chars)
      # @param url [String] Webhook URL (max 500 chars)
      # @param events [Array<String>] Event types to subscribe (min 1)
      # @param enabled [Boolean, nil] Enable webhook (default: true)
      # @return [Hash] Created webhook data including secret (shown only once)
      def create(route_id:, name:, url:, events:, enabled: nil)
        data = { route_id: route_id, name: name, url: url, events: events }
        data[:enabled] = enabled unless enabled.nil?
        @http_client.post(path: '/webhooks', data: data)
      end

      # Get webhook details.
      # @param id [String] Webhook ID
      # @return [Hash] Webhook data including secret
      def find(id)
        @http_client.get(path: "/webhooks/#{id}")
      end

      # Update a webhook.
      # @param id [String] Webhook ID
      # @param name [String, nil] New webhook name
      # @param url [String, nil] New webhook URL
      # @param enabled [Boolean, nil] Enable/disable webhook
      # @param events [Array<String>, nil] Event types (min 1)
      # @return [Hash] Updated webhook data
      def update(id, name: nil, url: nil, enabled: nil, events: nil)
        data = {}
        data[:name] = name if name
        data[:url] = url if url
        data[:enabled] = enabled unless enabled.nil?
        data[:events] = events if events
        @http_client.put(path: "/webhooks/#{id}", data: data)
      end

      # Delete a webhook.
      # @param id [String] Webhook ID
      # @return [Hash] Confirmation message
      def delete(id)
        @http_client.delete(path: "/webhooks/#{id}")
      end

      # Test a webhook by sending a test delivery.
      # @param id [String] Webhook ID
      # @return [Hash] Contains delivery_id for tracking
      def test(id)
        @http_client.post(path: "/webhooks/#{id}/test")
      end

      # Regenerate webhook secret.
      # @param id [String] Webhook ID
      # @return [Hash] Updated webhook data with new secret
      def regenerate_secret(id)
        @http_client.post(path: "/webhooks/#{id}/regenerate-secret")
      end

      # List webhook deliveries.
      # @param webhook_id [String] Webhook ID
      # @param page_size [Integer, nil] Number of items per page
      # @param page_cursor [String, nil] Cursor for pagination
      # @param sort [String, nil] Sort field: created_at, attempt_number
      # @param status [String, nil] Filter: pending, success, failed, client_error, server_error, timeout
      # @param event_type [String, nil] Filter by event type
      # @param from_date [String, nil] Filter from date (Y-m-d)
      # @param to_date [String, nil] Filter to date (Y-m-d)
      # @return [Hash] Paginated list of deliveries
      # rubocop:disable Metrics/ParameterLists
      def deliveries(webhook_id, page_size: nil, page_cursor: nil, sort: nil,
                     status: nil, event_type: nil, from_date: nil, to_date: nil)
        params = build_params(
          page_size: page_size,
          page_cursor: page_cursor,
          sort: sort,
          status: status,
          event_type: event_type,
          from_date: from_date,
          to_date: to_date
        )
        @http_client.get(path: "/webhooks/#{webhook_id}/deliveries", params: params)
      end
      # rubocop:enable Metrics/ParameterLists

      # Get a specific delivery.
      # @param webhook_id [String] Webhook ID
      # @param delivery_id [String] Delivery ID
      # @return [Hash] Delivery data including payload and response
      def delivery(webhook_id, delivery_id)
        @http_client.get(path: "/webhooks/#{webhook_id}/deliveries/#{delivery_id}")
      end
    end
  end
end
