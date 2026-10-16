# Pinned OpenAPI document

`lettermint-team-openapi.json` is the Lettermint Team API OpenAPI 3.1 document.

- Source: https://lettermint.co/docs/api-reference/team/0.0.1/lettermint-team-openapi.json
- Fetched: 2026-10-16
- API version in document: 0.0.1

It is the contract reference for error body shapes. The schemas the SDK's error parsing is checked against:

- `components.schemas.ApiError` — `{"error":{"code","message","details"}}`; `code` and `message` required,
  `details` is object, array or null
- `components.schemas.ErrorMessage` — `{"message"}`; `message` required
- `components.schemas.ValidationError` — `{"message","errors"}`

`spec/lettermint/openapi_contract_spec.rb` parses this file and fails if those shapes change. To refresh:

```bash
curl -fsSL https://lettermint.co/docs/api-reference/team/0.0.1/lettermint-team-openapi.json \
  -o spec/fixtures/openapi/lettermint-team-openapi.json
```

Update the fetch date above when you do.
