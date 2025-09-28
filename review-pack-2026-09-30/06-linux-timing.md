# Linux: timing a request

Based on [Linux.bash](../Linux.bash), which measures total HTTP request time.

## Exercise

Two requests have the same total time. One spends most of it before connecting; the other waits after sending. Why is total time alone insufficient?

## Suggested answer

Different stages can produce the same total. Capture DNS, connection, TLS, first-byte, and total timings before selecting a hypothesis. They are cumulative milestones, not separate durations to add together.

Example for an authorized endpoint; replace the URL:

```bash
curl --connect-timeout 5 --max-time 15 --silent --show-error \
  --output /dev/null \
  --write-out 'http=%{http_code} dns=%{time_namelookup} connect=%{time_connect} tls=%{time_appconnect} first_byte=%{time_starttransfer} total=%{time_total}\n' \
  'https://example.com/'
```

Record curl's exit code immediately after the command with `echo $?`. A network failure and an HTTP error are different observations: curl can exit successfully after receiving HTTP 500 unless configured to fail on HTTP errors.

Use a few controlled comparisons from the same machine. Report timestamp, endpoint, status, exit code, and timings. Do not infer a backend cause from a single slow sample; routing, DNS, TLS, server processing, and response transfer can all contribute.

Source: [curl manual](https://curl.se/docs/manpage.html).
