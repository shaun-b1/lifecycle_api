# API HTTP Status Codes

This document outlines the HTTP status codes used throughout the API and their meanings.

## Success Codes

| Code | Status     | Description                                                        | Usage                                                     |
| ---- | ---------- | ------------------------------------------------------------------ | --------------------------------------------------------- |
| 200  | OK         | The request was successful                                         | Used for successful GET (with data), PUT/PATCH operations |
| 201  | Created    | The request has been fulfilled and a new resource has been created | Used for successful POST operations                       |
| 204  | No Content | The request was successful but there is no content to return       | Used for successful DELETE operations                     |

## Client Error Codes

| Code | Status               | Description                                                                  | Usage                                            |
| ---- | -------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------ |
| 400  | Bad Request          | The request could not be understood or was missing required parameters       | Missing or invalid parameters                    |
| 401  | Unauthorized         | Authentication failed or user does not have permissions                      | Invalid or expired JWT token                     |
| 403  | Forbidden            | Authentication succeeded but user does not have access                       | User lacks permission for the requested resource |
| 404  | Not Found            | The requested resource could not be found                                    | Resource does not exist                          |
| 422  | Unprocessable Entity | The request was well-formed but unable to be followed due to semantic errors | Validation errors                                |
| 429  | Too Many Requests    | The user has sent too many requests in a given amount of time                | Rate limiting                                    |

## Server Error Codes

| Code | Status                | Description                                          | Usage                             |
| ---- | --------------------- | ---------------------------------------------------- | --------------------------------- |
| 500  | Internal Server Error | An unexpected condition was encountered              | Unhandled exceptions, server bugs |
| 503  | Service Unavailable   | The server is currently unable to handle the request | Server overload or maintenance    |

## Error Response Format

All error responses follow this standardized format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "A human-readable error message",
    "details": ["Additional error details if available"],
    "status": 400,
    "status_text": "Bad Request"
  }
}
```

## Success Response Format

All success responses follow this standardized format:

```json
{
  "success": true,
  "message": "A human-readable success message",
  "data": {}, // The requested data or resource
  "meta": {} // Additional metadata if available
}
```

Paginated responses include additional metadata:

```json
{
  "success": true,
  "data": [], // Collection of resources
  "meta": {
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_count": 100,
      "per_page": 20
    }
  }
}
```
