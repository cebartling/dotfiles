---
name: sqlserver-kerberos
description: Query Life Time SQL Server instances from this Mac using Kerberos (integrated) authentication via sqlcmd. Use when the user asks to query, inspect, or check a SQL Server database at Life Time, test a SQL Server connection, list databases on a SQL host, or run a read-only query against an LTFINC.NET server such as QAWSQL43 or the MMS databases. Covers the Microsoft ODBC 18 driver, the OpenSSL 3 requirement, the Kerberos ticket, and the hostname-vs-certificate gotcha.
---

# SQL Server via Kerberos (sqlcmd)

Connect to Life Time SQL Server with the Mac's Kerberos ticket (`-E`, integrated auth). No
passwords are stored or passed.

## Prerequisites

Check these before any query. Stop and report if one fails.

1. **Kerberos ticket** for `LTFINC.NET`:
   `klist` should show `krbtgt/LTFINC.NET@LTFINC.NET` and an unexpired expiry. If it is missing or
   expired, the user runs `kinit <user>@LTFINC.NET` in their own terminal (password prompt).
   Do not attempt `kinit` yourself.
2. **sqlcmd** on PATH: `command -v sqlcmd` → `/opt/homebrew/bin/sqlcmd`. Installed by the
   `microsoft/mssql-release/mssql-tools18` formula.
3. **ODBC driver**: `msodbcsql18` (`/opt/homebrew/lib/libmsodbcsql.18.dylib`), installed with
   `ACCEPT_EULA=Y`/`HOMEBREW_ACCEPT_EULA=Y` on install.
4. **OpenSSL 3** linked at `/opt/homebrew/opt/openssl` → `openssl@3`. The driver supports OpenSSL
   1.0, 1.1 and 3.0 only. If it points at `openssl@4`, every connection fails with
   `SSL Provider: [OpenSSL library could not be loaded...]`. Fix: `brew install openssl@3`, then
   `ln -sfn ../Cellar/openssl@3/<version> /opt/homebrew/opt/openssl` (ask the user before changing
   a Homebrew-managed link).

## Known hosts and databases

| Host | Use | Notes |
|---|---|---|
| `QAWSQL43.ltfinc.net` | QA instance (SQL Server 16 Developer) | Use this name. |
| `sqlqa-report.ltfinc.net` | Alias for QAWSQL43 | **Do not use.** TLS fails with "subject name does not match host name" because the cert is issued for `QAWSQL43`. |

Databases on QAWSQL43 that the user works with (all accessible to `LTFINC\<user>`):

- `MMS_Subscriber_QA`
- `Report_MMS_QA`

Other databases on the instance (`Batch_Subscriber_QA`, `CIS_Subscriber_QA`,
`Integration_Subscriber_QA`, `LTFEB_Subscriber_QA`, `MMS_Archive_Subscriber_QA`,
`Report_CIS_QA`, `Report_LTFEB_QA`, `DBA`, plus system DBs) are listed in `sys.databases` but are
not confirmed accessible; check before relying on one.

If the requested database is not on this list, ask the user for the host before guessing. `MMS`
alone does **not** exist on QAWSQL43.

## Connection command

Always pass `-E`, `-b` (exit non-zero on SQL errors), `-W` (trim spaces), and a timeout:

```bash
timeout 60 sqlcmd -S QAWSQL43.ltfinc.net -E -d <database> -b -W -h -1 -Q "<query>"
```

- `-h -1` suppresses headers for scripted output. Drop it when column names are needed.
- Do **not** add `-C` (trust server certificate) by default. It disables the TLS check. Only use it
  if the user explicitly asks and understands the trade-off.
- Use the `-Q` form for single batches; for a file, use `-i <file>`.

## Connectivity smoke test

Run this first, with no table reads:

```bash
timeout 60 sqlcmd -S QAWSQL43.ltfinc.net -E -d <database> -b -W -h -1 -Q \
  "SELECT DB_NAME() AS db, SUSER_NAME() AS login, USER_NAME() AS db_user, DATABASEPROPERTYEX(DB_NAME(),'Status') AS status, DATABASEPROPERTYEX(DB_NAME(),'Updateability') AS updateability;"
```

Expected: `<db>  LTFINC\<user>  LTFINC\<user>  ONLINE  READ_WRITE`.

## Read-only by default

- Default to `SELECT` and metadata queries (`sys.*`, `INFORMATION_SCHEMA.*`).
- Never run `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `DROP`, `ALTER`, `TRUNCATE`, `EXEC` of a
  procedure that writes, or DDL, unless the user explicitly asks for that exact statement against
  that exact database. Even though the login is `READ_WRITE`, treat the QA data as shared.
- Before running anything that writes, state the statement and target database and get a yes.

## Data sensitivity

Organization policy: do not include member PHI or HIPAA data in responses; PII is acceptable.

- Prefer aggregates, counts, schema, and column names over raw rows.
- When sampling rows is needed, cap it (`TOP 5`) and report only non-identifying columns; redact
  member identifiers and health information from anything shown back to the user.
- Do not write query results into the vault, the repo, or any file unless the user asks, and then
  only non-PHI results.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Client unable to establish connection` + `OpenSSL library could not be loaded` | `/opt/homebrew/opt/openssl` points at openssl@4 or nothing | Relink to openssl@3 (see Prerequisites #4). |
| `subject name does not match host name` | Using the alias `sqlqa-report.ltfinc.net` | Use `QAWSQL43.ltfinc.net`. |
| `Login failed for user 'LTFINC\<user>'` / `Cannot open database "X"` | Login has no access to X, or X doesn't exist on that instance | Check `sys.databases` for the name; ask the user. |
| `Cannot generate SSPI context` / Kerberos errors | No or expired ticket | Ask the user to run `kinit` in their terminal; check `klist`. |
| `sqlcmd: command not found` | `mssql-tools18` not installed | `brew bundle check --file=~/.dotfiles/Brewfile.lifetime`; install with `HOMEBREW_ACCEPT_EULA=Y brew install microsoft/mssql-release/msodbcsql18 microsoft/mssql-release/mssql-tools18`. |
| Hang with no output | Brew install waiting for a sudo password (pkg installer) | Ask the user to run the install in their own terminal (`!` prefix). |

## Reporting

2–4 lines: the server and database used, whether the connection and read succeeded, and the answer
to the question. Include the exact error text if a step fails.
