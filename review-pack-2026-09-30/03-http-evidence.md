# HTTP: evidence before diagnosis

Based on [HTTP notes](../http_notes.md), [cheat sheet](../http_cheat_sheet.md), and [Postman day 3](../postman_day_3/notes.md).

## Exercise

A form request returns HTTP 500. The user says “my data is wrong.” What can support say with confidence, and what evidence should be captured?

## Suggested answer

500 means the server encountered an unexpected condition while fulfilling the request. It does not identify the failing component or prove the root cause. Record method, sanitized URL, timestamp with timezone, status, response body, and request/correlation ID. Compare a minimal valid request with the failing request, using a test environment if reproduction could create data. Escalate the evidence to the service owner.

A successful HTTP status also does not establish that a business operation produced the desired result. Check the API contract and returned identifier, then verify the relevant read operation.

## Quick recall

- 401: authentication is required or credentials were not accepted.
- 403: the server refuses the operation.
- 404: the target is unavailable or its existence is concealed.
- POST: processes a submitted representation; the endpoint contract defines the effect.

Source: [HTTP Semantics, RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html).
