# Error response fixtures

Bodies used by `spec/lettermint/http_client_spec.rb` and `spec/lettermint/errors_spec.rb`
to exercise `Lettermint::ErrorBody.parse` and the typed error classes.

| File | Shape | Source |
|---|---|---|
| `not_found_api_error.json` | `{"error":{"code","message","details"}}` | `ApiError` schema in the Lettermint Team OpenAPI document |
| `not_found_error_message.json` | `{"message":"..."}` | `ErrorMessage` schema in the Lettermint Team OpenAPI document |
| `not_found_string_error.json` | `{"error":"..."}` | String-error shape handled by the official Node and Python SDKs (not in the OpenAPI document) |
| `not_found_proxy.html` | Minimal nginx-style HTML 404 page | Represents a reverse proxy answering before the API does; served with `Content-Type: text/html` |

The pinned OpenAPI document lives in `../openapi/`.

## Not yet captured

The real body returned by a live `GET /domains/<bogus-id>` has not been captured. The OpenAPI document
allows either `ApiError` or `ErrorMessage` for that 404 (`anyOf`), so the fixtures cover both. Replace
the relevant fixture with the captured body once one is available and note the capture date here.
