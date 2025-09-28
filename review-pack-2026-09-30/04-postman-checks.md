# Postman: echo is not persistence

Based on [day 1](../postman_day_1/notes.md), [day 2](../postman_day_2/notes.md), and [incident report 1](../incident_report_1.md).

## Exercise

A POST to an echo endpoint returns 200 and repeats your JSON. Does this prove that an order was saved?

## Suggested answer

It proves that the endpoint received and echoed that request. Persistence needs a separate API contract and an observable stored resource. Do not treat a training echo service as an order database.

## Small practice session

1. Set GET `https://postman-echo.com/get`, query parameter `city=Astana`.
2. Check that the response contains the query parameter.
3. Set POST `https://postman-echo.com/post`, JSON body `{"city":"Astana","purpose":"practice"}` and `Content-Type: application/json`.
4. Compare the echoed JSON with the sent body. Record the actual status; do not assume it.
5. Omit the body and compare the result. An empty body can be valid for some APIs; required fields depend on the contract.

Optional Postman post-response check for the POST example:

```javascript
pm.test("JSON was echoed", function () {
    const data = pm.response.json();
    pm.expect(data.json.city).to.eql("Astana");
});
```

Do not include credentials or personal data in public echo requests. Record the actual execution date and observation when you perform this exercise.

Reference: [Postman response test scripts](https://learning.postman.com/docs/tests-and-scripts/write-scripts/test-scripts/).
