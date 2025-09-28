# Support: form submission triage

Based on [support notes](../support_notes.md) and [incident report 6](../incident_report_6.md).

## Exercise

A user clicks Submit. No message appears, and the new record is absent. Choose the next observation for each branch.

| Observation | Next check | Working hypothesis |
| --- | --- | --- |
| No request appears in browser Network | Button handler, client validation, console error | Client path failed before sending |
| Request returns 400 | Required fields and response details | Request rejected by validation |
| Request returns 500 | Request ID and service logs | Server processing failed |
| Request returns success with resource ID | Retrieve that ID and check filters | Write/read contract, persistence, or visibility issue |

## Suggested answer

Start with scope, exact symptom, first observed time, and reproducibility. Keep “observed” separate from “suspected.” A success response plus an empty list is not enough to choose between a filter, cache, replica lag, or failed persistence.

Collect one reproducible example, check known incidents, assess affected users and business impact, then use the [handoff template](09-escalation-template.md). Give a workaround only if it is understood and permitted. Avoid repeated submissions until duplicate creation has been ruled out.

Success criterion: another person can reproduce the symptom and knows which check remains unresolved.
