# OpenAPI error schema extract

`error-schemas.json` is a trimmed extract of the Lettermint Team API OpenAPI 3.1 document. It keeps only the
parts the error contract spec reads; the full document is 11,000+ lines and changes often, so it is not stored.

- Source: https://lettermint.co/docs/api-reference/team/0.0.1/lettermint-team-openapi.json
- Fetched: 2026-10-16
- API version in document: 0.0.1

Contents:

- `components.schemas.ApiError` — `{"error":{"code","message","details"}}`; `code` and `message` required,
  `details` is object, array or null
- `components.schemas.ErrorMessage` — `{"message"}`; `message` required
- `components.schemas.ValidationError` — `{"message","errors"}`
- `paths./domains/{domainId}.get.responses.404` — declares `anyOf [ErrorMessage, ApiError]`

`spec/lettermint/openapi_contract_spec.rb` parses this file and fails if those shapes change. To refresh:

```bash
curl -fsSL https://lettermint.co/docs/api-reference/team/0.0.1/lettermint-team-openapi.json \
  | jq '{
      openapi,
      info: { title: .info.title, version: .info.version },
      paths: { "/domains/{domainId}": { get: { responses: { "404": .paths["/domains/{domainId}"].get.responses["404"] } } } },
      components: { schemas: { ApiError: .components.schemas.ApiError, ErrorMessage: .components.schemas.ErrorMessage, ValidationError: .components.schemas.ValidationError } }
    }' > spec/fixtures/openapi/error-schemas.json
```

Update the fetch date above when you do.
