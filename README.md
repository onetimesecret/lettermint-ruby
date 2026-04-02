# Lettermint Ruby SDK

[![Gem Version](https://img.shields.io/gem/v/lettermint?style=flat-square)](https://rubygems.org/gems/lettermint)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-red?style=flat-square)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://github.com/onetimesecret/lettermint-ruby/blob/main/LICENSE)

Unofficial Ruby SDK for the [Lettermint](https://lettermint.co) transactional email API. Based on the official [Python SDK](https://github.com/lettermint/lettermint-python).

The SDK provides two API clients:

- **SendingAPI** (aliased as `Client`) — Project-level email sending with `x-lettermint-token` authentication
- **TeamAPI** — Team-level management (domains, projects, webhooks, etc.) with `lm_team_*` token authentication

## Installation

Add to your Gemfile:

```ruby
gem 'lettermint'
```

Or install directly:

```bash
gem install lettermint
```

## Quick Start

### Sending Emails

```ruby
require 'lettermint'

# SendingAPI for email sending (aliased as Client for backward compatibility)
client = Lettermint::SendingAPI.new(api_token: 'your-project-token')

response = client.email
  .from('sender@example.com')
  .to('recipient@example.com')
  .subject('Hello from Ruby')
  .html('<h1>Welcome!</h1>')
  .text('Welcome!')
  .deliver

puts response.message_id
```

### Team Management

```ruby
# TeamAPI for team-level operations (requires lm_team_* token)
team_api = Lettermint::TeamAPI.new(team_token: 'lm_team_your-token')

# List domains
domains = team_api.domains.list
puts domains['data'].map { |d| d['domain'] }

# Get team info
team = team_api.team.get
puts team['name']
```

## Email Options

### Multiple Recipients

```ruby
client.email
  .from('sender@example.com')
  .to('recipient1@example.com', 'recipient2@example.com')
  .subject('Hello')
  .deliver
```

### CC and BCC

```ruby
client.email
  .from('sender@example.com')
  .to('recipient@example.com')
  .cc('cc1@example.com', 'cc2@example.com')
  .bcc('bcc@example.com')
  .subject('Hello')
  .deliver
```

### Reply-To

```ruby
client.email
  .from('sender@example.com')
  .to('recipient@example.com')
  .reply_to('reply@example.com')
  .subject('Hello')
  .deliver
```

### RFC 5322 Addresses

```ruby
client.email
  .from('John Doe <john@example.com>')
  .to('Jane Doe <jane@example.com>')
  .subject('Hello')
  .deliver
```

### Attachments

```ruby
require 'base64'

content = Base64.strict_encode64(File.binread('document.pdf'))

# Regular attachment
client.email
  .from('sender@example.com')
  .to('recipient@example.com')
  .subject('Your Document')
  .attach('document.pdf', content)
  .deliver

# Inline attachment (for embedding in HTML)
client.email
  .from('sender@example.com')
  .to('recipient@example.com')
  .subject('Welcome')
  .html('<img src="cid:logo@example.com">')
  .attach('logo.png', logo_content, content_id: 'logo@example.com')
  .deliver
```

You can also use the `EmailAttachment` value object:

```ruby
attachment = Lettermint::EmailAttachment.new(
  filename: 'document.pdf',
  content: content,
  content_id: nil
)

client.email
  .from('sender@example.com')
  .to('recipient@example.com')
  .attach(attachment)
  .deliver
```

### Custom Headers

```ruby
client.email
  .from('sender@example.com')
  .to('recipient@example.com')
  .subject('Hello')
  .headers({ 'X-Custom-Header' => 'value' })
  .deliver
```

### Metadata and Tags

```ruby
client.email
  .from('sender@example.com')
  .to('recipient@example.com')
  .subject('Hello')
  .metadata({ campaign_id: '123', user_id: '456' })
  .tag('welcome-campaign')
  .deliver
```

### Routing

```ruby
client.email
  .from('sender@example.com')
  .to('recipient@example.com')
  .subject('Hello')
  .route('my-route')
  .deliver
```

### Idempotency Key

Prevent duplicate sends when retrying failed requests:

```ruby
client.email
  .from('sender@example.com')
  .to('recipient@example.com')
  .subject('Hello')
  .idempotency_key('unique-request-id')
  .deliver
```

## Webhook Verification

Verify webhook signatures to ensure authenticity:

```ruby
require 'lettermint'

webhook = Lettermint::Webhook.new(secret: 'your-webhook-secret')

# Verify using headers (recommended)
payload = webhook.verify_headers(request.headers, request.body)

# Or verify using the signature directly
payload = webhook.verify(
  request.body,
  request.headers['X-Lettermint-Signature']
)

puts payload['event']
```

### Class Method

For one-off verification:

```ruby
payload = Lettermint::Webhook.verify_signature(
  request.body,
  request.headers['X-Lettermint-Signature'],
  secret: 'your-webhook-secret'
)
```

### Custom Tolerance

Adjust the timestamp tolerance (default: 300 seconds):

```ruby
webhook = Lettermint::Webhook.new(secret: 'your-webhook-secret', tolerance: 600)
```

### Replay Protection

The webhook verifier validates timestamp freshness and HMAC integrity but does not
track previously seen deliveries. Within the tolerance window (default 300 seconds),
a captured request could be replayed. Your application should deduplicate incoming
webhooks using the `x-lettermint-delivery` header value as an idempotency key -- for
example, by recording processed delivery IDs in a database or cache and rejecting
duplicates.

## TeamAPI

The TeamAPI provides access to team-level management operations. It requires a team token (prefixed with `lm_team_`).

```ruby
team_api = Lettermint::TeamAPI.new(team_token: 'lm_team_your-token')
```

### Available Resources

| Resource | Methods |
|----------|---------|
| `team` | `get`, `update`, `usage`, `members` |
| `domains` | `list`, `create`, `find`, `delete`, `verify_dns`, `verify_dns_record`, `update_projects` |
| `projects` | `list`, `create`, `find`, `update`, `delete`, `rotate_token`, `add_member`, `remove_member`, `update_members`, `routes` |
| `webhooks` | `list`, `create`, `find`, `update`, `delete`, `test`, `deliveries`, `delivery`, `regenerate_secret` |
| `messages` | `list`, `find`, `html`, `text`, `source`, `events` |
| `suppressions` | `list`, `create`, `delete` |
| `routes` | `list`, `create`, `find`, `update`, `delete`, `verify_inbound_domain` |
| `stats` | `get` |

### Examples

```ruby
# Domains
team_api.domains.create(domain: 'mail.example.com')
team_api.domains.verify_dns('domain-id')

# Projects
projects = team_api.projects.list(sort: '-created_at')
project = team_api.projects.create(name: 'My Project')
team_api.projects.rotate_token(project['id'])

# Webhooks
team_api.webhooks.create(
  name: 'My Webhook',
  url: 'https://example.com/webhook',
  events: ['message.sent', 'message.delivered']
)

# Messages (search and retrieve)
messages = team_api.messages.list(status: 'delivered', tag: 'welcome')
html_body = team_api.messages.html('message-id')

# Suppressions
team_api.suppressions.create(
  emails: ['bounce@example.com'],
  reason: 'hard_bounce',
  scope: 'project',
  project_id: 'project-id'
)

# Stats
stats = team_api.stats.get(from: '2026-01-01', to: '2026-01-31')
```

### Pagination

All list methods support cursor-based pagination:

```ruby
# First page
result = team_api.domains.list(page_size: 10)

# Next page
if result['meta']['next_cursor']
  next_page = team_api.domains.list(
    page_size: 10,
    page_cursor: result['meta']['next_cursor']
  )
end
```

### Sorting and Filtering

```ruby
# Sort by field (prefix with - for descending)
team_api.projects.list(sort: '-created_at')
team_api.domains.list(sort: 'domain')

# Filter by field
team_api.messages.list(status: 'delivered', from_email: 'noreply@example.com')
team_api.domains.list(status: 'verified')
```

## Raw HTTP Methods

The SendingAPI provides raw HTTP methods for accessing API endpoints not yet wrapped in typed methods:

```ruby
client = Lettermint::SendingAPI.new(api_token: 'your-api-token')

# GET with query params
response = client.get('/some-endpoint', params: { limit: 10 })

# POST with JSON body
response = client.post('/some-endpoint', data: { key: 'value' })

# PUT
response = client.put('/some-endpoint/123', data: { key: 'new-value' })

# DELETE
client.delete('/some-endpoint/123')
```

## Error Handling

```ruby
require 'lettermint'

client = Lettermint::SendingAPI.new(api_token: 'your-api-token')

begin
  response = client.email
    .from('sender@example.com')
    .to('recipient@example.com')
    .subject('Hello')
    .deliver
rescue Lettermint::AuthenticationError => e
  # 401/403 errors (invalid or revoked token)
  puts "Auth error #{e.status_code}: #{e.message}"
rescue Lettermint::RateLimitError => e
  # 429 errors
  puts "Rate limited, retry after: #{e.retry_after}s"
rescue Lettermint::ValidationError => e
  # 422 errors (e.g., daily limit exceeded)
  puts "Validation error: #{e.error_type}"
  puts "Response: #{e.response_body}"
rescue Lettermint::ClientError => e
  # 400 errors
  puts "Client error: #{e.message}"
rescue Lettermint::TimeoutError => e
  # Request timeout
  puts "Timeout: #{e.message}"
rescue Lettermint::ConnectionError => e
  # Network-level failures (DNS, connection refused, etc.)
  puts "Connection error: #{e.message}"
  puts "Original: #{e.original_exception}" if e.original_exception
rescue Lettermint::HttpRequestError => e
  # Other HTTP errors
  puts "HTTP error #{e.status_code}: #{e.message}"
end
```

### Webhook Errors

```ruby
begin
  payload = webhook.verify_headers(headers, body)
rescue Lettermint::InvalidSignatureError
  puts 'Invalid signature - request may be forged'
rescue Lettermint::TimestampToleranceError
  puts 'Timestamp too old - possible replay attack'
rescue Lettermint::WebhookJsonDecodeError => e
  puts "Invalid JSON in payload: #{e.original_exception}"
rescue Lettermint::WebhookVerificationError => e
  puts "Verification failed: #{e.message}"
end
```

## Configuration

### Global Configuration

Set defaults once at application boot (e.g., in a Rails initializer):

```ruby
Lettermint.configure do |config|
  config.timeout = 60
end
```

All clients created afterward inherit these defaults.

### Per-Client Overrides

```ruby
client = Lettermint::SendingAPI.new(api_token: 'your-api-token', timeout: 10)
```

## Requirements

- Ruby >= 3.2
- [Faraday](https://github.com/lostisland/faraday) ~> 2.0

## License

MIT
