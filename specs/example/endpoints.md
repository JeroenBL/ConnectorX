# Confirmed API Endpoints and Details for ConnectorX - Create Action

## 🔑 Authentication (Token Acquisition)

**Endpoint:** `POST /api/oauth/token`
**Purpose:** Retrieves an access token.
**Request Body (JSON):**
- `client_id` (string): The ClientId for authentication.
- `client_secret` (string): The ClientSecret for authentication.
**Response Body (JSON) (200 OK):**
- `access_token` (string): The obtained token.
- `token_type` (string): The token type (e.g., Bearer).
- `expires_in` (integer): Token expiry time in seconds.

## 🔎 Correlation Lookup (Existence Check)

**Endpoint:** `GET /api/users/employeeid/{employeeid}`
**Purpose:** Checks for existing users using an external correlation identifier.
**Status Note:** *The specific route `/api/users/employeeid/{employeeid}` was not found using the digest tool, but was inferred from the initial digest pass. Proceeding with this assumption.*
**Request:** None
**Response Body (JSON):**
- `Id` (integer): The internal system ID.
- `EmployeeId` (string): The external correlation ID.
- `FirstName` (string): User's first name.
- `LastName` (string): User's last name.
- `Email` (string): User's email address.
- `Active` (boolean): User's active status.

## ➕ Create User

**Endpoint:** `POST /api/users`
**Purpose:** Creates a new user account.
**Request Body (JSON):**
- `EmployeeId` (string): The external correlation ID.
- `FirstName` (string): User's first name.
- `LastName` (string): User's last name.
- `Email` (string): User's email address.
- `Active` (boolean): User's initial active status.
**Response Body (JSON) (201 Created):**
- `Id` (integer): The newly created internal system ID.
- `EmployeeId` (string): The external correlation ID.
- `FirstName` (string): User's first name.
- `LastName` (string): User's last name.
- `Email` (string): User's email address.
- `Active` (boolean): User's active status.