# frozen_string_literal: true

module Lettermint
  # Backward compatibility: Client is an alias for SendingAPI.
  # Use Lettermint::SendingAPI explicitly for clarity.
  Client = SendingAPI
end
