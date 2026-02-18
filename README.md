# Lettermint Ruby SDK

[![Gem Version](https://img.shields.io/gem/v/lettermint?style=flat-square)](https://rubygems.org/gems/lettermint)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-red?style=flat-square)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://github.com/onetimesecret/lettermint-ruby/blob/main/LICENSE)

Unofficial Ruby SDK for the [Lettermint](https://lettermint.co) transactional email API. Based on the official [Python SDK](https://github.com/lettermint/lettermint-python).

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

client = Lettermint::Client.new(api_token: 'your-api-token')

response = client.email
  .from('sender@example.com')
  .to('recipient@example.com')
  .subject('Hello from Ruby')
  .html('<h1>Welcome!</h1>')
  .text('Welcome!')
  .deliver

puts response.message_id
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

## Error Handling

```ruby
require 'lettermint'

client = Lettermint::Client.new(api_token: 'your-api-token')

begin
  response = client.email
    .from('sender@example.com')
    .to('recipient@example.com')
    .subject('Hello')
    .deliver
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

### Custom Base URL

```ruby
client = Lettermint::Client.new(
  api_token: 'your-api-token',
  base_url: 'https://custom.api.com/v1'
)
```

### Custom Timeout

```ruby
client = Lettermint::Client.new(
  api_token: 'your-api-token',
  timeout: 60
)
```

### Block Configuration

```ruby
client = Lettermint::Client.new(api_token: 'your-api-token') do |config|
  config.base_url = 'https://custom.api.com/v1'
  config.timeout = 60
end
```

## Requirements

- Ruby >= 3.2
- [Faraday](https://github.com/lostisland/faraday) ~> 2.0

## License

MIT
