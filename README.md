# ConnectorX

<p align="left">
  <img src="https://raw.githubusercontent.com/JeroenBL/ConnectorX/refs/heads/main/x.png" width="500">
</p>

## Introduction

Hi 👋

If you're looking to create a new target connector for HelloID provisioning and don't know where to start, you're in the right place.

__ConnectorX__ is the perfect starting point for building out your new connector, with all the essential resources you'll need to get started.

And the best part... __you don't have to code anything!__ :partying_face:

No more staring at a blank wondering which code goes where. No more copy-pasting logic and hoping it still works.
__ConnectorX__ reads an OpenAPI spec, asks you the two or three things only a human should decide, and writes the rest. :sunglasses:

### Getting started

1. Open a terminal in the repo.
2. Drop the OpenAPI where ConnectorX expects it.
3. Type the command.`/new-connector <target> <action(s)>`
   - `<target>`
   a short name for the system you're connecting to, e.g. `example`
   - `<action(s)>`
   comma-separated: `create`, `update`, `enable`, `disable`, `delete`. Ask for just one or all five.

    **Examples**
    ```
    /new-connector example create
    /new-connector example create,update,disable
4. Wait for the API endpoints proposal.
    >  ConnectorX will come back with something like:<br>
    > Proposed endpoints for `target`:
    > - Token: `POST /oauth/token` (body: client_id, client_secret)
    > - Correlation lookup: `GET /users/employeeid/{id}`
    > - Create: `POST /users`
    >
    > Confirm?
5. Confirm the proposal.
6. Let __ConnectorX__ finish the work.
