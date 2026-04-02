# frozen_string_literal: true

# Raw HTTP Methods Example
#
# The raw HTTP methods allow you to access any Lettermint API endpoint,
# even those not yet wrapped in typed SDK methods.
#
# Usage:
#   LETTERMINT_API_TOKEN=xxx bundle exec ruby examples/raw_http.rb

require 'lettermint'

api_token = ENV.fetch('LETTERMINT_API_TOKEN') do
  abort 'Set LETTERMINT_API_TOKEN environment variable'
end

client = Lettermint::Client.new(api_token: api_token)

# Test connectivity
puts 'Testing API connectivity...'
begin
  result = client.get('/ping')
  puts "Ping response: #{result}"
rescue Lettermint::Error => e
  puts "Error: #{e.message}"
end

# Example: List domains (if using Team API token)
# result = client.get('/domains')
# puts "Domains: #{result}"

# Example: Create a domain
# result = client.post('/domains', data: { domain: 'mail.example.com' })
# puts "Created domain: #{result['id']}"

# Example: Get with query parameters
# result = client.get('/messages', params: { status: 'delivered', limit: 50 })
# puts "Messages: #{result}"

# Example: Delete a resource
# result = client.delete('/domains/dom_123')
# puts "Deleted: #{result}"

# Example: Custom headers
# result = client.get('/data', headers: { 'X-Request-Id' => 'req-123' })
# puts "Data: #{result}"
