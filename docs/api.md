# Lettermint Team API Reference

`https://api.lettermint.co/v1` · Auth: `Authorization: Bearer {team_token}`

Pagination: cursor-based via `page[size]` (default 30), `page[cursor]`. Sorting: comma-separated fields, `-` prefix for desc.

**Conventions:** `?` = nullable/optional, `*` = required, defaults in parens. List variants omit nested includes. `?include=` params noted per endpoint.

---

## Enums

| Name | Values |
|------|--------|
| AttachmentDelivery | `inline` `url` |
| DnsRecordStatus | `active` `failed` `pending` |
| DomainStatus | `verified` `partially_verified` `pending_verification` `failed_verification` |
| InitialRoutes | `both` `transactional` `broadcast` |
| MessageEventType | `queued` `processed` `suppressed` `delivered` `soft_bounced` `hard_bounced` `spam_complaint` `failed` |
| MessageStatus | `pending` `queued` `suppressed` `processed` `delivered` `opened` `clicked` `soft_bounced` |
| MessageType | `inbound` `outbound` |
| Plan | `free` `starter` `growth` `pro` |
| RecordType | `TXT` `CNAME` `MX` |
| RouteType | `transactional` `broadcast` `inbound` |
| SuppressionReason | `spam_complaint` `hard_bounce` `unsubscribe` `manual` |
| SuppressionScope | `global` `team` `project` `route` |
| SuppressionType | `email` `domain` `extension` |
| VolumeTier | `300` `10k` `50k` `125k` `500k` `750k` `1M` `1.5M` |
| WebhookDeliveryStatus | `pending` `success` `failed` `client_error` `server_error` `timeout` |
| WebhookEvent | `message.{created,sent,delivered,hard_bounced,soft_bounced,spam_complaint,failed,suppressed}` |

---

## Generic

| | |
|---|---|
| `GET /ping` | Health check. Also accepts `X-Lettermint-Token: {project_token}` |

---

## Team

| | |
|---|---|
| `GET /team` | `?include=features,featuresCount,featuresExists` |
| `PUT /team` | Body: `{name}` |
| `GET /team/usage` | Current period + up to 12 historical |
| `GET /team/members` | Paginated |

```
TeamData { id, name, plan: Plan, tier: VolumeTier, verified_at?, created_at,
  features: string[], addons: [{type?, expires_at?}],
  domains_count?, projects_count?, members_count? }
TeamMemberData { id, role?, joined_at?, user?: {id, name, email, avatar?} }
UsageDetail { current_period, historical_usage[]: {usage: int, last_incremented_at?, period_start, period_end} }
```

---

## Domains

| | |
|---|---|
| `GET /domains` | `filter[status]`, `filter[domain]` · `sort`: domain, created_at, status_changed_at |
| `POST /domains` | Body: `{domain*}` (max 255, regex validated) |
| `GET /domains/{id}` | `?include=dnsRecords,dnsRecordsCount,dnsRecordsExists` |
| `DELETE /domains/{id}` | |
| `POST /domains/{id}/dns-records/verify` | Verify all records |
| `POST /domains/{id}/dns-records/{recordId}/verify` | Verify single |
| `PUT /domains/{id}/projects` | Body: `{project_ids[]}` |

```
DomainData { id, domain, status_changed_at?, created_at, dns_records[], projects[] }
DomainListData { id, domain, status: DomainStatus, status_changed_at?, created_at }
DnsRecord { id, type: RecordType, hostname, fqdn, content,
  status: DnsRecordStatus, verified_at?, last_checked_at? }
```

---

## Projects

| | |
|---|---|
| `GET /projects` | `filter[search]` · `sort`: name, created_at |
| `POST /projects` | Body: `{name*, smtp_enabled? (false), initial_routes? (both)}`. Returns `api_token` |
| `GET /projects/{id}` | `?include=routes,domains,teamMembers,messageStats` (+ Count/Exists) |
| `PUT /projects/{id}` | Body: `{name?, smtp_enabled?, default_route_id?}` |
| `DELETE /projects/{id}` | |
| `POST /projects/{id}/rotate-token` | Returns `new_token` |
| `PUT /projects/{id}/members` | Body: `{team_member_ids[]}` |
| `POST /projects/{id}/members/{memberId}` | Add member |
| `DELETE /projects/{id}/members/{memberId}` | Remove member |

```
ProjectData { id, name, smtp_enabled: bool, default_route_id?,
  token_generated_at?, token_last_used_at?, token_last_used_ip?,
  created_at, updated_at,
  routes[], domains[], team_members[],
  last_28_days: {messages_transactional, messages_broadcast, messages_inbound: int, deliverability: float} }
ProjectListData { id, name, smtp_enabled, routes_count, domains_count,
  team_members_count, last_28_days, created_at, updated_at }
```

---

## Routes

| | |
|---|---|
| `GET /projects/{id}/routes` | `filter[route_type]`, `filter[is_default]`, `filter[search]` · `sort`: name, slug, created_at |
| `POST /projects/{id}/routes` | Body: `{name*, route_type*, slug?}` |
| `GET /routes/{id}` | `?include=project,statistics` |
| `PUT /routes/{id}` | Body: `{name?, settings{track_opens, track_clicks, disable_hosted_unsubscribe}?, inbound_settings{inbound_domain, inbound_spam_threshold, attachment_delivery}?}` |
| `DELETE /routes/{id}` | |
| `POST /routes/{id}/verify-inbound-domain` | |

```
RouteData { id, project_id, slug, name, route_type: RouteType, is_default: bool,
  created_at, updated_at,
  inbound_address?, inbound_domain?, inbound_domain_verified_at?,
  inbound_spam_threshold?, attachment_delivery?,
  project?, webhooks_count?, suppressed_recipients_count?, statistics? }
RouteListData { id, slug, name, route_type, is_default,
  webhooks_count, suppressed_recipients_count, created_at, updated_at }
RouteStatistic { date, sent_count, delivered_count, opened_count, clicked_count,
  hard_bounce_count, spam_complaint_count, inbound_received_count }
```

---

## Messages

| | |
|---|---|
| `GET /messages` | `filter[type]`, `filter[status]`, `filter[route_id]`, `filter[domain_id]`, `filter[tag]`, `filter[from_email]`, `filter[subject]`, `filter[from_date]`, `filter[to_date]` · `sort`: type, status, from_email, subject, created_at, status_changed_at |
| `GET /messages/{id}` | Full detail |
| `GET /messages/{id}/events` | `sort`: timestamp, event |
| `GET /messages/{id}/source` | Returns `message/rfc822` |
| `GET /messages/{id}/html` | Returns `text/html` |
| `GET /messages/{id}/text` | Returns `text/plain` |

```
MessageData { id, type: MessageType, status: MessageStatus, status_changed_at?,
  tag?, from_email, from_name?, reply_to?, subject?,
  to?, cc?, bcc?: [{email, name?}],
  attachments?: [{size (0), filename ("unknown"), content_id?, content_type ("application/octet-stream")}],
  metadata?, route_id, created_at, spam_score?, spam_symbols?: [{name, score, options[], description?}] }
MessageListData { id, type, status, from_email, from_name?, subject?,
  to?, cc?, bcc?, reply_to?, tag?, created_at }
MessageEvent { message_id, event: MessageEventType, metadata?, timestamp }
```

---

## Webhooks

| | |
|---|---|
| `GET /webhooks` | `filter[enabled]`, `filter[event]`, `filter[route_id]`, `filter[search]` · `sort`: name, url, created_at |
| `POST /webhooks` | Body: `{route_id*, name*, url*, events[]*, enabled? (true)}`. Returns `secret` (shown once) |
| `GET /webhooks/{id}` | |
| `PUT /webhooks/{id}` | Body: `{name?, url?, enabled?, events[]?}` |
| `DELETE /webhooks/{id}` | |
| `POST /webhooks/{id}/test` | Returns `delivery_id` |
| `POST /webhooks/{id}/regenerate-secret` | Returns new `secret` |
| `GET /webhooks/{id}/deliveries` | `filter[status]`, `filter[event_type]`, `filter[from_date]`, `filter[to_date]` |
| `GET /webhooks/{id}/deliveries/{deliveryId}` | Full payload/response |

```
WebhookData { id, route_id, name, url, events: WebhookEvent[], enabled: bool,
  last_called_at?, created_at, updated_at, secret? }
WebhookDelivery { id, webhook_id, event_type: WebhookEvent, status: WebhookDeliveryStatus,
  attempt_number, http_status_code?, duration_ms?,
  payload[], response_body?, response_headers?, error_message?,
  delivered_at?, timestamp }
WebhookDeliveryList { ...sans payload/response_body/response_headers/error_message, + created_at }
```

---

## Suppressions

| | |
|---|---|
| `GET /suppressions` | `filter[scope]`, `filter[route_id]`, `filter[project_id]`, `filter[value]`, `filter[reason]` · `sort`: value, created_at, reason |
| `POST /suppressions` | Body: `{reason*, scope*, email?, emails[]? (max 1000), route_id?, project_id?}` |
| `DELETE /suppressions/{id}` | |

```
SuppressedRecipient { id, type: SuppressionType, value, reason: SuppressionReason,
  scope: SuppressionScope, project_id?, route_id?, created_at, updated_at }
```

---

## Stats

| | |
|---|---|
| `GET /stats` | `from*` (Y-m-d), `to*` (Y-m-d, max 90 days span), `project_id?` |

```
StatsData { from, to, totals: StatsTotals, daily: StatsDaily[] }
StatsTotals / StatsDaily { sent, delivered, hard_bounced, spam_complaints: int,
  opened?, clicked?: int (null if tracking disabled),
  inbound: {received: int},
  transactional, broadcast: {sent, hard_bounced, spam_complaints: int} }
```
