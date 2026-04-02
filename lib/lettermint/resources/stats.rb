# frozen_string_literal: true

module Lettermint
  module Resources
    # Stats resource for retrieving email statistics.
    class Stats < Base
      # Get statistics for a date range.
      # @param from [String] Start date (Y-m-d format, required)
      # @param to [String] End date (Y-m-d format, required, max 90 days from start)
      # @param project_id [String, nil] Filter by project ID
      # @param route_id [String, nil] Filter by a single route ID
      # @param route_ids [Array<String>, String, nil] Filter by multiple route IDs
      # @return [Hash] Stats data with totals and daily breakdown
      def get(from:, to:, project_id: nil, route_id: nil, route_ids: nil)
        params = { 'from' => from, 'to' => to }
        params['project_id'] = project_id if project_id
        params['route_id'] = route_id if route_id
        params['route_ids'] = route_ids if route_ids
        @http_client.get(path: '/stats', params: params)
      end
    end
  end
end
