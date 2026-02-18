# frozen_string_literal: true

require 'lettermint'

# Rack/Sinatra example
webhook = Lettermint::Webhook.new(secret: ENV.fetch('LETTERMINT_WEBHOOK_SECRET'))

# From headers approach (typical in a web framework)
# headers = request.headers
# body = request.body.read
# event = webhook.verify_headers(headers, body)

# Direct verification
signature = 't=1234567890,v1=abcdef...'
payload = '{"event":"email.delivered","data":{"message_id":"msg_123"}}'

begin
  event = webhook.verify(payload, signature)
  puts "Verified event: #{event['event']}"
rescue Lettermint::InvalidSignatureError
  puts 'Invalid signature'
rescue Lettermint::TimestampToleranceError
  puts 'Stale webhook'
rescue Lettermint::WebhookJsonDecodeError
  puts 'Invalid payload JSON'
end

# Static convenience method
# event = Lettermint::Webhook.verify_signature(payload, signature, secret: "whsec_...")
