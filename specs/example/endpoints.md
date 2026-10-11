# API Specification Digest for ConnectorX - example

## Security
The system uses OAuth2 Bearer Token authentication. A token must be acquired via the dedicated token endpoint before making any calls.

### Token Acquisition
*   **Endpoint:** `POST /api/oauth/token`
*   **Purpose:** Retrieve Bearer Token
*   **Request Body Fields:** `client_id`, `client_secret`
*   **Response Fields:** `access_token`, `token_type`, `expires_in`
*   **Notes:** This token must be used in the Authorization header (`Bearer <token>`) for all subsequent secured API calls.

---

## Endpoints

### 👤 User Management (General Lookup)
*   **Endpoint:** `GET /api/users`
*   **Purpose:** Retrieve all users.
*   **Request Fields:** None.
*   **Response Fields:** `Id`, `EmployeeId`, `FirstName`, `LastName`, `Email`, `Active`.

### 🧑‍💼 Correlation Lookup (By Correlation Field)
*   **Endpoint:** `GET /api/users/employeeid/{employeeid}`
*   **Purpose:** Retrieve user details using a person's identifier.
*   **Path Parameters:** `employeeid`
*   **Request Fields:** None.
*   **Response Fields:** `Id`, `EmployeeId`, `FirstName`, `LastName`, `Email`, `Active`.

### 🆕 Create User
*   **Endpoint:** `POST /api/users`
*   **Purpose:** Create a new user account.
*   **Request Body Fields:** `Id`, `EmployeeId`, `FirstName`, `LastName`, `Email`, `Active`.
*   **Response Fields:** `Id`, `EmployeeId`, `FirstName`, `LastName`, `Email`, `Active`.
*   **Notes:** The `Id` field should be provided in the request body but treated as read-only/internal during creation, as per connector conventions.

### 🆔 Internal ID Lookup (By System ID)
*   **Endpoint:** `GET /api/users/{id}`
*   **Purpose:** Retrieve user details using the target system's unique ID.
*   **Path Parameters:** `id` (Target System ID)
*   **Request Fields:** None.
*   **Response Fields:** `Id`, `EmployeeId`, `FirstName`, `LastName`, `Email`, `Active`.

### 🔄 Update User
*   **Endpoint:** `PATCH /api/users/{id}`
*   **Purpose:** Partially update an existing user.
*   **Path Parameters:** `id`
*   **Request Body Fields:** `Operations`, `ContractResolver`
*   **Response Fields:** `Id`, `EmployeeId`, `FirstName`, `LastName`, `Email`, `Active`.

### 🗑️ Delete User
*   **Endpoint:** `DELETE /api/users/{id}`
*   **Purpose:** Delete a user.
*   **Path Parameters:** `id`
*   **Request Body Fields:** None.
*   **Response Fields:** None.