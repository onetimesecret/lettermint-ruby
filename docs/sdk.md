# Lettermint Ruby SDK Reference

`gem 'lettermint'` v0.2.0 · Ruby >= 3.2

---

## Quick Start

```ruby
require 'lettermint'

# Sending API (project-level email sending)
client = Lettermint::SendingAPI.new(api_token: 'lm_project_xxx')

# Team API (team-level management)
team = Lettermint::TeamAPI.new(team_token: 'lm_team_xxx')
```

---

## Authentication

| API | Token Format | Header |
|-----|--------------|--------|
| SendingAPI | `lm_project_*` | `x-lettermint-token` |
| TeamAPI | `lm_team_*` | `Authorization: Bearer` |

```ruby
# Global configuration (optional)
Lettermint.configure do |config|
  config.base_url = 'https://api.lettermint.co/v1'
  config.timeout = 30
end

# Instance-level configuration
client = Lettermint::SendingAPI.new(api_token: 'xxx', base_url: 'https://...', timeout: 60)
```

---

## Sending Emails

```ruby
client = Lettermint::SendingAPI.new(api_token: 'lm_project_xxx')

# Fluent builder API
response = client.email
  .from('sender@example.com')
  .to('recipient@example.com')
  .subject('Hello')
  .html('<h1>Hello World</h1>')
  .text('Hello World')
  .deliver

response.message_id  # => "msg_xxx"
response.status      # => "queued"
```

### EmailMessage Methods

| Method | Description |
|--------|-------------|
| `from(email)` | Sender address (required) |
| `to(*emails)` | Recipient(s) (required, accepts array) |
| `subject(str)` | Subject line (required) |
| `html(str)` | HTML body |
| `text(str)` | Plain text body |
| `cc(*emails)` | CC recipients |
| `bcc(*emails)` | BCC recipients |
| `reply_to(*emails)` | Reply-to addresses |
| `route(slug)` | Route slug |
| `tag(str)` | Message tag |
| `headers(hash)` | Custom headers |
| `metadata(hash)` | Custom metadata |
| `attach(filename, content, content_id:)` | Add attachment |
| `idempotency_key(key)` | Idempotency key header |
| `deliver` | Send the email, returns `SendEmailResponse` |

### Attachments

```ruby
# Simple attachment
client.email
  .from('sender@example.com')
  .to('recipient@example.com')
  .subject('Report')
  .html('<p>See attached</p>')
  .attach('report.pdf', Base64.strict_encode64(pdf_data))
  .deliver

# With content ID (for inline images)
client.email
  .attach('logo.png', base64_data, content_id: 'logo')
  .html('<img src="cid:logo">')
  ...

# Using EmailAttachment type
attachment = Lettermint::EmailAttachment.new(
  filename: 'doc.pdf',
  content: base64_data,
  content_id: nil
)
client.email.attach(attachment)...
```

---

## Team API Resources

```ruby
team = Lettermint::TeamAPI.new(team_token: 'lm_team_xxx')
```

### Generic

```ruby
team.ping  # => { 'ok' => true }
```

### Team

```ruby
# Get team details
team.team.get                                    # => Hash
team.team.get(include: 'features,featuresCount') # with includes

# Update team
team.team.update(name: 'New Name')

# Usage statistics
team.team.usage  # => { current_period: ..., historical_usage: [...] }

# List members (paginated)
team.team.members(page_size: 50, page_cursor: 'cursor_xxx')
```

### Domains

```ruby
# List domains
team.domains.list
team.domains.list(status: 'verified', sort: '-created_at', page_size: 10)

# Create domain
team.domains.create(domain: 'mail.example.com')

# Get domain
team.domains.find('dom_xxx')
team.domains.find('dom_xxx', include: 'dnsRecords')

# Delete domain
team.domains.delete('dom_xxx')

# Verify DNS records
team.domains.verify_dns('dom_xxx')                      # all records
team.domains.verify_dns_record('dom_xxx', 'rec_xxx')   # single record

# Update associated projects
team.domains.update_projects('dom_xxx', project_ids: ['proj_1', 'proj_2'])
```

### Projects

```ruby
# List projects
team.projects.list
team.projects.list(search: 'api', sort: 'name')

# Create project
team.projects.create(
  name: 'My Project',
  smtp_enabled: true,
  initial_routes: 'transactional'  # both, transactional, broadcast
)
# => { ..., 'api_token' => 'lm_project_xxx' }

# Get project
team.projects.find('proj_xxx')
team.projects.find('proj_xxx', include: 'routes,domains,messageStats')

# Update project
team.projects.update('proj_xxx',
  name: 'Renamed',
  smtp_enabled: false,
  default_route_id: 'route_xxx'
)

# Delete project
team.projects.delete('proj_xxx')

# Rotate API token
team.projects.rotate_token('proj_xxx')  # => { 'new_token' => '...' }

# Manage members
team.projects.update_members('proj_xxx', team_member_ids: ['mem_1', 'mem_2'])
team.projects.add_member('proj_xxx', 'mem_xxx')
team.projects.remove_member('proj_xxx', 'mem_xxx')
```

### Routes

```ruby
# Project-scoped routes
routes = team.projects.routes('proj_xxx')

routes.list
routes.list(route_type: 'transactional', is_default: true, sort: '-created_at')

routes.create(
  name: 'Notifications',
  route_type: 'transactional',  # transactional, broadcast, inbound
  slug: 'notifications'
)

# Direct route access (any route by ID)
team.routes.find('route_xxx')
team.routes.find('route_xxx', include: 'project,statistics')

team.routes.update('route_xxx',
  name: 'Renamed',
  settings: { track_opens: true, track_clicks: true },
  inbound_settings: { inbound_domain: 'in.example.com', inbound_spam_threshold: 5 }
)

team.routes.delete('route_xxx')
team.routes.verify_inbound_domain('route_xxx')
```

### Messages

```ruby
# List messages
team.messages.list
team.messages.list(
  type: 'outbound',
  status: 'delivered',
  route_id: 'route_xxx',
  from_date: '2024-01-01',
  to_date: '2024-01-31',
  sort: '-created_at'
)

# Get message
team.messages.find('msg_xxx')

# Message events (delivery history)
team.messages.events('msg_xxx')
team.messages.events('msg_xxx', sort: '-timestamp')

# Message content
team.messages.source('msg_xxx')  # RFC822 format
team.messages.html('msg_xxx')    # HTML body
team.messages.text('msg_xxx')    # Plain text body
```

### Webhooks

```ruby
# List webhooks
team.webhooks.list
team.webhooks.list(enabled: true, event: 'message.delivered', route_id: 'route_xxx')

# Create webhook (returns secret once)
result = team.webhooks.create(
  route_id: 'route_xxx',
  name: 'Delivery notifications',
  url: 'https://example.com/webhooks',
  events: ['message.delivered', 'message.hard_bounced'],
  enabled: true
)
secret = result['secret']  # Store this securely

# Get webhook
team.webhooks.find('wh_xxx')

# Update webhook
team.webhooks.update('wh_xxx', name: 'Renamed', enabled: false)

# Delete webhook
team.webhooks.delete('wh_xxx')

# Test webhook
team.webhooks.test('wh_xxx')  # => { 'delivery_id' => '...' }

# Regenerate secret
team.webhooks.regenerate_secret('wh_xxx')  # => { 'secret' => '...' }

# Webhook deliveries
team.webhooks.deliveries('wh_xxx')
team.webhooks.deliveries('wh_xxx', status: 'failed', from_date: '2024-01-01')
team.webhooks.delivery('wh_xxx', 'del_xxx')  # Full delivery details
```

### Suppressions

```ruby
# List suppressions
team.suppressions.list
team.suppressions.list(scope: 'team', reason: 'hard_bounce')

# Create suppression
team.suppressions.create(
  reason: 'manual',      # spam_complaint, hard_bounce, unsubscribe, manual
  scope: 'team',         # global, team, project, route
  email: 'bad@example.com'
)

# Bulk suppress (up to 1000)
team.suppressions.create(
  reason: 'manual',
  scope: 'project',
  project_id: 'proj_xxx',
  emails: ['a@example.com', 'b@example.com']
)

# Delete suppression
team.suppressions.delete('sup_xxx')
```

### Stats

```ruby
# Get statistics (max 90 day range)
team.stats.get(from: '2024-01-01', to: '2024-03-31')
team.stats.get(from: '2024-01-01', to: '2024-01-31', project_id: 'proj_xxx')
team.stats.get(from: '2024-01-01', to: '2024-01-31', route_ids: ['r1', 'r2'])

# Returns:
# {
#   'from' => '2024-01-01',
#   'to' => '2024-01-31',
#   'totals' => { 'sent' => 1000, 'delivered' => 980, ... },
#   'daily' => [{ 'date' => '2024-01-01', 'sent' => 50, ... }, ...]
# }
```

---

## Webhook Verification

Standalone module, no client dependency.

```ruby
# Instance-based
webhook = Lettermint::Webhook.new(secret: 'whsec_xxx', tolerance: 300)

# Verify from headers (recommended)
payload = webhook.verify_headers(request.headers, request.raw_body)
# => parsed JSON hash

# Verify from signature string
payload = webhook.verify(raw_body, signature_header)

# Class method (one-shot)
payload = Lettermint::Webhook.verify_signature(
  raw_body,
  signature_header,
  secret: 'whsec_xxx',
  tolerance: 300
)
```

### Signature Format

Header: `x-lettermint-signature: t=<unix_ts>,v1=<hex_hmac>`
Timestamp: `x-lettermint-delivery: <unix_ts>`

---

## Error Handling

```ruby
begin
  client.email.from('x').to('y').subject('z').html('...').deliver
rescue Lettermint::ValidationError => e
  e.message        # Error message
  e.status_code    # 422
  e.error_type     # Validation error type
  e.response_body  # Raw response
rescue Lettermint::ClientError => e
  e.status_code    # 400
rescue Lettermint::AuthenticationError => e
  e.status_code    # 401 or 403
rescue Lettermint::RateLimitError => e
  e.retry_after    # Seconds to wait (may be nil)
rescue Lettermint::TimeoutError
  # Request timed out
rescue Lettermint::ConnectionError => e
  e.original_exception  # Underlying Faraday error
rescue Lettermint::ResponseParsingError => e
  e.original_exception  # Faraday::ParsingError
rescue Lettermint::HttpRequestError => e
  # Catch-all for HTTP errors
rescue Lettermint::Error => e
  # Catch-all for SDK errors
end
```

### Webhook Errors

```ruby
begin
  webhook.verify_headers(headers, body)
rescue Lettermint::InvalidSignatureError
  # HMAC mismatch
rescue Lettermint::TimestampToleranceError
  # Timestamp too old or future
rescue Lettermint::WebhookJsonDecodeError => e
  e.original_exception  # JSON::ParserError
rescue Lettermint::WebhookVerificationError
  # Catch-all for webhook errors
end
```

---

## Error Hierarchy

```
Lettermint::Error
├── HttpRequestError (status_code, response_body)
│   ├── ValidationError (422, error_type)
│   ├── ClientError (400)
│   ├── AuthenticationError (401/403)
│   └── RateLimitError (429, retry_after)
├── TimeoutError
├── ConnectionError (original_exception)
├── ResponseParsingError (original_exception)
└── WebhookVerificationError
    ├── InvalidSignatureError
    ├── TimestampToleranceError
    └── WebhookJsonDecodeError (original_exception)
```

---

## Types

```ruby
# SendEmailResponse (Data.define, frozen)
response = client.email...deliver
response.message_id  # String
response.status      # String

# EmailAttachment (Data.define, frozen)
attachment = Lettermint::EmailAttachment.new(
  filename: 'report.pdf',
  content: Base64.strict_encode64(data),
  content_id: nil  # optional
)
attachment.to_h  # => { filename: ..., content: ... }
```

---

## Pagination

All list methods support cursor-based pagination:

```ruby
# First page
result = team.domains.list(page_size: 10)
items = result['data']
cursor = result.dig('meta', 'cursor')

# Next page
if cursor
  result = team.domains.list(page_size: 10, page_cursor: cursor)
end
```

---

## Raw HTTP Access

For endpoints not yet wrapped in typed methods:

```ruby
client = Lettermint::SendingAPI.new(api_token: 'xxx')

client.get('/some/endpoint', params: { key: 'value' })
client.post('/some/endpoint', data: { key: 'value' })
client.put('/some/endpoint', data: { key: 'value' })
client.delete('/some/endpoint')
```
