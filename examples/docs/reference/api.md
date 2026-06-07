# API reference

## `GET /v1/things/{id}`

Fetch a single thing.

=== "Request"
    ```http
    GET /v1/things/42 HTTP/1.1
    Host: api.example.com
    Authorization: Bearer <token>
    ```

=== "Response"
    ```json
    {
      "id": 42,
      "name": "answer",
      "created_at": "2026-06-01T12:00:00Z"
    }
    ```

## `POST /v1/things`

Create a new thing.

| Field   | Type     | Required | Description           |
| ------- | -------- | -------- | --------------------- |
| `name`  | `string` | yes      | Human-readable label. |
| `kind`  | `string` | no       | Defaults to `generic`.|
