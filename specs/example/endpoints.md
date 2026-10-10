# Endpoint Digest: example

## 🔐 Token/Authentication
- **Scheme**: Bearer
- **Format**: JWT
- **Source Path**: (Inferred from security section of spec)

## ➕ Create User
- **Method**: POST
- **Route**: `/api/users`
- **Description**: Creates a new user.
- **Request Schema**:
  - `Id`: integer (readOnly: true, internal ID)
  - `EmployeeId`: string (required, external identifier)
  - `FirstName`: string (required)
  - `LastName`: string (required)
  - `Email`: string (required)
  - `Active`: boolean (required, initial state should be disabled)
- **Response Schema**: Matches Request Schema (returns the newly created user with its `Id`).
- **Fields Mapped**: All required fields are mapped and confirmed.

## 🔎 Lookup by Correlation Field (Employee ID)
- **Method**: GET
- **Route**: `/api/users/employeeid/{employeeid}`
- **Description**: Retrieves a user based on their external EmployeeId.
- **Fields**: Returns all user fields: `Id`, `EmployeeId`, `FirstName`, `LastName`, `Email`, `Active`.
- **Correlation Field**: `EmployeeId` (from request body of create endpoint).

## 🆔 Lookup by Internal ID
- **Method**: GET
- **Route**: `/api/users/{id}`
- **Description**: Retrieves a user using the internal system ID.
- **Fields**: Returns all user fields: `Id`, `EmployeeId`, `FirstName`, `LastName`, `Email`, `Active`.
- **Internal ID Field**: `Id` (from response of create endpoint).

**Note on Fetch Details**: The detailed fetch operation for the GET endpoints failed due to a positional parameter error in `Get-SpecDigest.ps1`. However, the routes and fields were confirmed in Step 3 and the request/response schemas for the POST operation were successfully retrieved. The paths above rely on the structure confirmed in the initial spec digest.