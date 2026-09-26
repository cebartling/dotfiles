---
name: prod-snapshot-acceptance
description: Export the WICI production MongoDB, load it into the local Docker Compose MongoDB, reset every password to password123, make sure wici-api and wici-client are running locally, and run the full wici-acceptance-tests suite against that stack. Use when the user asks to "test against a prod snapshot", "load prod data locally and run the acceptance tests", "refresh local DB from production", or invokes /prod-snapshot-acceptance.
tools: Bash
---

# prod-snapshot-acceptance

Refresh the local `wici-db` with a production export, then run every acceptance spec against the
local stack. Run all paths from the workspace root
`~/github-sandbox/schoolhouse-educational-services`.

## Safety rules

- Production is **read-only** here: the only `:prod` script allowed is `export:prod`.
  Never run `import:prod`, `reset-passwords:prod`, or `test:prod`.
- Before any write (import or password reset), confirm the target env file points at
  `mongodb://localhost:27017/wici-db`. If it doesn't, stop and tell the user.
- Redact credentials when printing env files:
  `sed -E 's#(mongodb(\+srv)?://)[^@]*@#\1***@#' <file>`
- Never touch port :5000 (macOS AirPlay).

## Workflow

### 1. Preflight

```bash
sed -E 's#(mongodb(\+srv)?://)[^@]*@#\1***@#' wici-tools/database-import-export/.env.local
sed -E 's#(mongodb(\+srv)?://)[^@]*@#\1***@#' wici-tools/cleanse-local-dev/.env.local
grep -v -i pass wici-acceptance-tests/.env.local
lsof -iTCP -sTCP:LISTEN -P | grep -E ':(3000|5001|27017) '
```

The active (uncommented) `MONGODB_URI` in both tool `.env.local` files must be
`mongodb://localhost:27017/wici-db`. `wici-acceptance-tests/.env.local` should have
`BASE_URL=http://localhost:3000`.

Tell the user which branch each repo is on (`git -C <repo> branch --show-current` for `wici-api`,
`wici-client`, `wici-acceptance-tests`). The tests run against whatever is checked out, and the
skill does not switch branches.

### 2. Export production (read-only)

Write to a dated directory so earlier exports aren't overwritten:

```bash
cd wici-tools/database-import-export
bun run export:prod -- -o exports/production-$(date +%Y-%m-%d)
```

Record the per-collection document counts for the summary.

### 3. Start Docker Compose services

If :27017 isn't listening, start them:

```bash
cd wici-api && npm run docker:up && docker compose ps
```

Wait until `wici-api-mongo` reports `healthy`. If the containers are already up and healthy,
leave them alone.

### 4. Load the export into local MongoDB

Validate first, then import. The import **drops each collection before inserting**, so it
replaces the local data in those collections.

```bash
cd wici-tools/database-import-export
bun run import:local -- exports/production-<date> --dry-run
bun run import:local -- exports/production-<date>
```

Stop if the dry run reports any invalid file.

### 5. Reset passwords to password123

The acceptance tests and local sign-in rely on the cleansed password:

```bash
cd wici-tools/cleanse-local-dev && bun run reset-passwords:local 2>&1 | tail -3
```

### 6. Make sure wici-api and wici-client are running

API on :5001 against local `wici-db`:

- If :5001 is already listening, check which DB it uses:
  `ps eww -p <pid> | tr ' ' '\n' | grep DOTENV_CONFIG_PATH`. It should be `.env.dev.local`,
  which points at `mongodb://localhost:27017/wici-db`. If it points anywhere else, tell the user
  before going on.
- Otherwise start it in the background:
  `cd wici-api && DOTENV_CONFIG_PATH=.env.dev.local npm run dev`

Client on :3000: if it isn't listening, start `cd wici-client && npm start` in the background
(with `BROWSER=none`).

Wait until both answer: `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/` returns
200, and anything other than a connection failure comes back from :5001 (the API root returns
404, which is fine).

If a server is already running, don't restart it. The API re-reads the database on each request,
so it doesn't need a restart after the import.

### 7. Run the full acceptance suite

Run it in the background with the output saved to the scratchpad, keeping Playwright's exit code
(don't let a trailing `echo` hide it):

```bash
cd wici-acceptance-tests && bun run test:local --reporter=line > <scratchpad>/acceptance.log 2>&1; echo "playwright exit=$?" >> <scratchpad>/acceptance.log
```

When it finishes, read the tail of the log for the passed/failed/skipped/flaky totals. For
failures, pull out each failing spec's title and error. Don't rerun or change anything to make
tests pass unless the user asks.

## Report

Give the user:

- The export directory and per-collection counts.
- Import result, and the number of passwords reset.
- Whether services were started or already running, plus the branch of each repo.
- Acceptance totals (passed/failed/skipped/flaky, duration), failing specs with errors, and the
  log path.
- A reminder that `exports/production-<date>/` holds real production data (emails, password
  hashes) in plain JSON and should be deleted when they're done with it.
