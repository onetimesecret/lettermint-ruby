# Error response fixtures

Bodies used by `spec/lettermint/http_client_spec.rb` and `spec/lettermint/errors_spec.rb` to exercise
`Lettermint::ErrorBody.parse` and the typed error classes.

Captured 2026-10-16 against `https://api.lettermint.co/v1` with a Team token. Every captured response had
`Content-Type: application/json` and no `Retry-After` header. Bodies are stored verbatim, including the
pretty-print whitespace the API emits on `ErrorMessage` responses.

| File | Request | Status | Shape |
|---|---|---|---|
| `not_found_api_error.json` | `GET /domains/dom_0000000000000000` | 404 | `ApiError`, `code: RESOURCE_NOT_FOUND` |
| `not_found_error_message.json` | `GET /this-route-does-not-exist` | 404 | `ErrorMessage` (router 404) |
| `unauthorized_api_error.json` | `GET /domains` with no token header | 401 | `ApiError`, `code: UNAUTHORIZED` |
| `unauthorized_empty_message.json` | `GET /domains` with an invalid or empty token | 401 | `ErrorMessage` with blank `message` |
| `not_found_string_error.json` | not observed | 404 | `{"error":"<string>"}` |
| `not_found_proxy.html` | not observed | 404 | Minimal nginx-style HTML page, served as `text/html` |

`DELETE /domains/dom_0000000000000000` and `GET /projects/dom_0000000000000000` returned a 404 body identical
to `not_found_api_error.json`, so one fixture covers all three.

`not_found_string_error.json` is a shape the official Node and Python SDKs handle defensively; it was not
observed from the live API. `not_found_proxy.html` represents a reverse proxy answering before the API does.

## Resource 404 vs router 404

A 404 for a missing resource is an `ApiError` with `code == "RESOURCE_NOT_FOUND"`. A 404 for an unknown route
is an `ErrorMessage` with no `code`. Callers distinguish the two with `e.code` on `Lettermint::NotFoundError`.

The OpenAPI document declares `anyOf [ErrorMessage, ApiError]` for the domain 404 responses. In practice the
domain 404 resolves to `ApiError`; `ErrorMessage` appears for unknown routes.

## details

`details` was absent on every observed body. The `ApiError` fixtures therefore have no `details` key, and the
specs that assert `details` is `nil` prove absent-key handling rather than explicit-null handling.

The blank `message` on the invalid-token 401 exercises the blank-message fallback: the gem raises
`AuthenticationError` with message `"HTTP 401"` and `code nil`.

The OpenAPI error schema extract lives in `../openapi/`.
