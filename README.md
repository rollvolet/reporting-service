# Reporting service
Microservice generating reports on the CRM data

## Getting started
### Adding the service to your stack
Add the following snippet to your `docker-compose.yml` to include the reporting service in your project.

```yml
reporting:
  image: rollvolet/reporting-service
```

## Reference
### API
#### POST /revenue-reports
Generate a report listing total revenue per month for a given timeframe

##### Request
The request body contains the range (in years) to generate the report for. By default the report will be generated for the last 5 years.

```json
{
  "data": {
    "type": "revenue-reports",
    "attributes": {
      "from-year": 2019,
      "until-year": 2022
    }
  }
}
```

##### Response
- `201 Created` if the report has been generated succesfully. The response body contains a list of monthly sales entries.

```json
{
  "data": [
    {
      "id": "1/2019",
      "type": "monthly-sales-entries",
      "attributes": {
        "month": 1,
        "year": 2019,
        "amount": 2342.57
      }
    },
    ...
  ]
}
```
