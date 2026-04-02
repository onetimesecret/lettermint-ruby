# frozen_string_literal: true

module Lettermint
  module Resources
    # Base class for Team API resources providing shared functionality.
    class Base
      def initialize(http_client:)
        @http_client = http_client
      end

      private

      # Builds query parameters for list endpoints.
      # @param page_size [Integer, nil] Number of items per page
      # @param page_cursor [String, nil] Cursor for pagination
      # @param sort [String, nil] Sort field (prefix with - for descending)
      # @param include [String, nil] Related resources to include
      # @param filters [Hash] Filter parameters (converted to filter[key]=value)
      # @return [Hash, nil] Query parameters hash or nil if empty
      def build_params(page_size: nil, page_cursor: nil, sort: nil, include: nil, **filters)
        params = {
          'page[size]' => page_size,
          'page[cursor]' => page_cursor,
          'sort' => sort,
          'include' => include
        }.compact

        filters.each { |k, v| params["filter[#{k}]"] = v unless v.nil? }
        params.empty? ? nil : params
      end
    end
  end
end
