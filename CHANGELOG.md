# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-04-01

### Added

- `TeamAPI` for managing team resources (members, invitations)
- `SendingAPI` for domain and sender identity management
- Resource class infrastructure (`BaseResource`, `Resource`)
- Raw HTTP methods (`Client#get`, `#post`, `#put`, `#delete`) for arbitrary endpoint access
- `ConnectionError` for network-level failures

### Changed

- HTTP response body validation before JSON parsing

### Fixed

- TypeError leak in webhook header parsing
- Blank recipient validation

[0.2.0]: https://github.com/onetimesecret/lettermint-ruby/compare/v0.1.0...v0.2.0

## [0.1.0] - 2026-02-18

### Added

- Email sending via `Client#email` with fluent builder interface
- Support for to, cc, bcc, reply-to, attachments, custom headers, metadata, tags, and routing
- `deliver` method (avoids `Object#send` collision)
- Idempotency key support for safe retries
- `SendEmailResponse` and `EmailAttachment` frozen value objects (`Data.define`)
- HMAC-SHA256 webhook signature verification via `Webhook`
- Timestamp tolerance checking (default 300s)
- Instance and class-level verification methods
- Typed error hierarchy: `HttpRequestError`, `ValidationError`, `ClientError`, `TimeoutError`, `WebhookVerificationError`, `InvalidSignatureError`, `TimestampToleranceError`, `WebhookJsonDecodeError`
- Faraday-based HTTP transport with `x-lettermint-token` authentication
- Block-style client configuration
- Full RSpec test suite (86 examples)
- RuboCop configuration

[0.1.0]: https://github.com/onetimesecret/lettermint-ruby/releases/tag/v0.1.0
