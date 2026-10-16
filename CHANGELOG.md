# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2026-10-16

### Added

- `NotFoundError` for HTTP 404 responses (subclass of `HttpRequestError`)
- `code` and `details` readers on `HttpRequestError`, inherited by every subclass

### Changed

- Error bodies are parsed from the three shapes used by the official Lettermint SDKs: `{"error":{"code","message","details"}}`, `{"error":"<string>"}`, and `{"message":"<string>"}`
- Error message resolves from `error.message`, then top-level `message`, then `"HTTP <status>"`; the per-status fallback literals (`Unknown client error`, `Validation error`, `Rate limit exceeded`) are removed
- `response_body` keeps non-JSON bodies as a String (for example an HTML 404 page from a proxy); empty bodies are nil
- A String `error` value is now exposed as `code` and no longer used as the message; a 400 with `{"error":"..."}` and no `message` reports `HTTP 400`

### Fixed

- 400 responses with an `{"error":{...}}` body produced a stringified Hash as the message
- 422 responses with an `{"error":{...}}` body set `error_type` to a Hash; it is now the `code` string

[0.2.1]: https://github.com/onetimesecret/lettermint-ruby/compare/v0.2.0...v0.2.1

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
