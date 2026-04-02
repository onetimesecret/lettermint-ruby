# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Lettermint Ruby SDK (`lettermint` gem, v0.1.0) — a client library for the Lettermint transactional email API. Ruby >= 3.2, MIT license.

## Commands

```bash
bundle exec rspec                          # run all specs
bundle exec rspec spec/lettermint/client_spec.rb        # run one spec file
bundle exec rspec spec/lettermint/client_spec.rb:10     # run single example by line
bundle exec rubocop                        # lint
bundle exec rubocop -a                     # lint + auto-fix
bundle exec rake                           # default task: spec + rubocop
```

## Architecture

The SDK has two independent subsystems sharing a common error hierarchy:

**Email sending** — `Client` → `EmailMessage` → `HttpClient` → Faraday
- `Client` is the entry point; instantiated with `api_token:` and optional `base_url:`/`timeout:` or a configuration block
- `Client#email` returns an `EmailMessage` builder with a fluent/chainable API (`.from().to().subject().html().deliver`)
- `EmailMessage#deliver` POSTs to `/send`, returns a `SendEmailResponse` (Data.define), then resets internal state
- `HttpClient` wraps Faraday; authenticates via `x-lettermint-token` header; maps HTTP status codes to typed exceptions

**Raw HTTP access** — `Client#get`, `#post`, `#put`, `#delete`
- Delegates to `HttpClient` for accessing arbitrary API endpoints not yet wrapped in typed methods
- Returns raw `Hash` (parsed JSON); typed errors bubble up unchanged
- Example: `client.get('/domains', params: { limit: 10 })`, `client.post('/domains', data: { domain: 'example.com' })`

**Webhook verification** — `Webhook` (standalone, no Client dependency)
- HMAC-SHA256 signature verification with timestamp tolerance (default 300s)
- Signature format: `t=<unix_ts>,v1=<hex_hmac>` — parsed from `x-lettermint-signature` header
- `verify_headers` is the high-level entry point (takes headers hash + raw payload)
- Class method `verify_signature` provides a one-shot convenience API

**Error hierarchy:**
```
Error
├── HttpRequestError (has status_code, response_body)
│   ├── ValidationError (422, has error_type)
│   └── ClientError (400)
├── TimeoutError
└── WebhookVerificationError
    ├── InvalidSignatureError
    ├── TimestampToleranceError
    └── WebhookJsonDecodeError (has original_exception)
```

**Value types** — `SendEmailResponse` and `EmailAttachment` use `Data.define` (frozen value objects).

## Testing

- RSpec with WebMock (`WebMock.disable_net_connect!` — no real HTTP in tests)
- Specs mirror `lib/` structure under `spec/lettermint/`
- Rubocop config: 120 char line length, block length exemption for specs

## Style

- `frozen_string_literal: true` on every file
- Keyword arguments for constructors (`api_token:`, `secret:`, etc.)
- All HTTP errors are raised as typed exceptions, never raw Faraday errors
