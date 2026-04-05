# Quickstart: Edit & Delete LLM Targets and Attacks

**Date**: 2026-04-05
**Branch**: `003-edit-delete-entries`

## Prerequisites

- Node.js (for frontend dev server)
- Backend running at `http://localhost:8080`
- PostgreSQL running via `docker compose up -d postgres`
- At least one LLM target and one attack template exist (create via
  the "Add new..." buttons if needed)

## Steps

1. Rebuild and start the backend (new endpoints):
   ```bash
   cd backend && cabal build && cabal run attack-harness
   ```

2. Start the frontend dev server:
   ```bash
   cd frontend && npm run dev
   ```

3. Open `http://localhost:5173`, go to the **Attack Builder** tab.

## Verify: Edit an LLM Target

1. Scroll to the **Registered Targets** table.
2. Click **Edit** on any target row.
3. Change the model name to something different (e.g., `llama3-edited`).
4. Click **Save**.
5. Verify the updated model name appears in the targets table and in
   the Target dropdown above.

## Verify: Edit an Attack Template

1. Scroll to the **Attack Templates** table.
2. Click **Edit** on any attack row.
3. Change the description text.
4. Click **Save**.
5. Verify the updated description appears in the attacks table and
   dropdown.

## Verify: Delete an Unreferenced Entry

1. Create a new LLM target via "Add new..." (give it a unique name).
2. In the targets table, click **Delete** on that new target.
3. Confirm the deletion when prompted.
4. Verify the target disappears from the table and dropdown.

## Verify: Delete Blocked by Run History

1. Find a target or attack that has been used in at least one run.
2. Click **Delete** on that entry.
3. Verify the system shows a message that the entry cannot be deleted
   because it has associated run history.
4. Verify the entry is NOT removed.

## Verify: Edit Validation

1. Click **Edit** on any target.
2. Clear the **Name** field (leave it empty).
3. Click **Save**.
4. Verify a validation error appears and the form does not submit.
5. Click **Cancel** and verify no changes were made.
