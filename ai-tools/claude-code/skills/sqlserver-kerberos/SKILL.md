---
name: sqlserver-kerberos
description: Query Life Time SQL Server instances from this Mac using Kerberos (integrated) authentication via sqlcmd. Use when the user asks to query, inspect, or check a SQL Server database at Life Time, test a SQL Server connection, list databases on a SQL host, or run a read-only query against an LTFINC.NET server such as QAWSQL43 or the MMS databases, or against the Dev, QA, Stage or Prod-replica LTSuite and Report servers. Covers the Microsoft ODBC 18 driver, the OpenSSL 3 requirement, the Kerberos ticket, and the hostname-vs-certificate gotcha.
---

# SQL Server via Kerberos (sqlcmd)

Connect to Life Time SQL Server with the Mac's Kerberos ticket (`-E`, integrated auth). No
passwords are stored or passed.

## Prerequisites

Check these before any query. Stop and report if one fails.

1. **Kerberos ticket** for `LTFINC.NET`:
   `klist` should show `krbtgt/LTFINC.NET@LTFINC.NET` and an unexpired expiry. If it is missing or
   expired, the user runs `kinit <user>@LTFINC.NET` in their own terminal (password prompt).
   Do not attempt `kinit` yourself. A TGT lasts 10 hours. After any AD group change the user must
   `kinit` again, because group membership is embedded in the ticket when it is issued.
   `/etc/krb5.conf` must set `default_realm = LTFINC.NET` and map `.ltfinc.net`/`ltfinc.net` to it.
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

With sqlcmd, always connect by the **real server** name, never the alias. The aliases are CNAMEs and
TLS fails with "subject name does not match host name" because the cert is issued for the real
server. Resolve an alias with `dig +short <alias>.ltfinc.net`. (The Confluence page lists short
alias names for JetBrains tools; those do not apply to sqlcmd.)

Verified through sqlcmd on 2026-11-18 unless marked otherwise. The Confluence page "Kerberos on
macOS (needed for on-prem SQL Server connections)" is partly stale: its Stage Report and Prod
server names no longer match DNS.

| Environment | Alias (do not use) | Real server (use with `-S`) | Status |
|---|---|---|---|
| Dev LTSuite | `sqldev-ltsuite` | `DEVWSQL41.ltfinc.net` | Verified |
| Dev Report | `sqldev-report` | `DEVWSQL43.ltfinc.net` | Verified |
| QA LTSuite | `sqlqa-ltsuite` | `QAWSQL41.ltfinc.net` or `QAWSQL42.ltfinc.net` | Verified. The alias resolves to cluster name `SQLQA-LTSUITE22`, which fails TLS (cert mismatch) under sqlcmd. Which node is primary is unknown (HADR role query is permission-denied); both show the same databases. Stick to reads. |
| QA Report | `sqlqa-report` | `QAWSQL43.ltfinc.net` | Verified. SQL Server 16 Developer. Used to alias `qawsql03` (pre-migration, still answers); do not use that name or its IP. |
| Stage LTSuite | `sqlstg-ltsuite` | `SQLSTG-LTSUITE2.ltfinc.net` (cluster name) | **Fails**: TLS cert mismatch under sqlcmd; Confluence also reports error 906 (missing cluster SPN, DB team incident open). Do not use. |
| Stage Report | `sqlstg-report` | `STGWSQL43.ltfinc.net` | Verified. Confluence says `STGWSQL27`, which does not resolve. |
| Prod (report replica) | `sqlprd-report` | `PRDWSQL43.ltfinc.net` | Verified 2026-11-18 (needs `SEC-DB-LTSUITE-RO`). Confluence says `PRDWSQL28`, which is stale. See "Production". |

Databases the user's login can open (system DBs omitted):

| Server | Databases |
|---|---|
| `DEVWSQL41` | `Acquisition_Dev`, `Batch_Dev`, `CIS_Dev`, `DBAImport`, `Integration_Dev`, `LTFEB_Dev`, `MMS_Contract_Dev`, `MMS_Dev` |
| `DEVWSQL43` | `Batch_Subscriber_Dev`, `CIS_Subscriber_Dev`, `Integration_Subscriber_Dev`, `LTFEB_Subscriber_Dev`, `MMS_Archive_Subscriber_Dev`, `MMS_Subscriber_Dev`, `Report_CIS_Dev`, `Report_LTFEB_Dev`, `Report_MMS_Dev`, `distribution` |
| `QAWSQL41` / `QAWSQL42` | `Acquisition_QA`, `Batch_QA`, `CIS_QA`, `Integration_QA`, `LTFEB_QA`, `MMS_Contract_QA`, `MMS_QA` |
| `QAWSQL43` | `MMS_Subscriber_QA`, `Report_MMS_QA` (the user works with these); others such as `Batch_Subscriber_QA`, `CIS_Subscriber_QA`, `Integration_Subscriber_QA`, `LTFEB_Subscriber_QA`, `MMS_Archive_Subscriber_QA`, `Report_CIS_QA`, `Report_LTFEB_QA`, `DBA` are in `sys.databases` but not confirmed accessible |
| `STGWSQL43` | `Batch_Subscriber_Stg`, `CIS_Subscriber_Stg`, `Integration_Subscriber_Stg`, `LTFEB_Subscriber_Stg`, `MMS_Archive_Subscriber_Stg`, `MMS_Subscriber_Stg`, `Report_CIS_Stg`, `Report_LTFEB_Stg`, `Report_MMS_Stg`, `distribution` |
| `PRDWSQL43` (Prod) | `Batch_Subscriber`, `CIS_Subscriber`, `DBAImport`, `Integration`, `LTFEB_Subscriber`, `MMS`, `MMS_Archive`, `Report_CIS`, `Report_LTFEB`, `Report_MMS`, `distribution` |

The LTSuite hosts hold the primary transactional databases; the Report hosts hold the `*_Subscriber_*`
and `Report_*` replicas. If the requested database is not listed, check
`SELECT name FROM sys.databases WHERE HAS_DBACCESS(name)=1` and ask the user before guessing a host.
`MMS` alone does **not** exist on QAWSQL43.

## Access: AD groups

Kerberos only proves identity. Which servers a login can use is controlled by AD group membership,
which the DB team does not manage. Access is requested through the Database Access Request
(ServiceNow) process; for prod read-only choose **LTF Suite - Read Only** and name the group.

| Group | Grants | Covers |
|---|---|---|
| `SEC-DB-LTSUITE-Developers` | Read-write-execute | Dev, QA, Stage. Does **not** cover Prod. |
| `SEC-DB-LTSUITE-RO` | Read-only | Prod report replica. Coverage of lower environments is unconfirmed. |

If Kerberos succeeds but the login fails with error 18456, the user is authenticated but not in the
right group for that server. Report it; do not retry or switch to `-C`.

## Production

- Only the report replica is permitted: `sqlprd-report`, currently `PRDWSQL43.ltfinc.net`, database
  `Report_MMS`. Re-resolve it with `dig` first; the Confluence name `PRDWSQL28` is stale.
- User connections to `sqlprd-ltsuite` are not permitted; do not try it.
- `Report_MMS` reports `READ_WRITE` updateability for the user's login, so the server will not stop a
  write. The read-only rule below is enforced by this skill alone.
- Do not connect to Prod unless the user explicitly names it for that request.
- Prod is read-only: `SELECT` and metadata queries only, aggregates preferred, no write statements
  under any circumstances (the "ask first" path for writes does not apply to Prod).

## Connection command

Always pass `-E`, `-b` (exit non-zero on SQL errors), `-W` (trim spaces), and a timeout:

```bash
timeout 60 sqlcmd -S <server> -E -d <database> -b -W -h -1 -Q "<query>"
```

- `-h -1` suppresses headers for scripted output. Drop it when column names are needed.
- Do **not** add `-C` (trust server certificate) by default. It disables the TLS check. Only use it
  if the user explicitly asks and understands the trade-off.
- Use the `-Q` form for single batches; for a file, use `-i <file>`.

## Connectivity smoke test

Run this first, with no table reads:

```bash
timeout 60 sqlcmd -S <server> -E -d <database> -b -W -h -1 -Q \
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
| `subject name does not match host name` | Using an alias such as `sqlqa-report.ltfinc.net` | Use the real server from the hosts table (e.g. `QAWSQL43.ltfinc.net`). |
| `Login failed for user 'LTFINC\<user>'` (18456) | Kerberos worked, but the user is not in the AD group for that server, or the ticket predates a group change | See "Access: AD groups"; after a group change the user runs `kinit` again. |
| `Cannot open database "X"` | X doesn't exist on that instance, or no access | Check `sys.databases` for the name; ask the user. |
| Error 906 on every host-name form (clustered instance) | `MSSQLSvc` SPN not registered on the cluster virtual name (this was QA's problem; Stage LTSuite has it now) | DB team fix. Report it and stop; do not work around it. |
| `Login timeout expired` / `TCP Provider: Error code 0x2AF9` | Host not resolvable or reachable, usually VPN is off | Ask the user to check VPN; `klist` is a separate check. |
| `Cannot generate SSPI context` / Kerberos errors | No or expired ticket | Ask the user to run `kinit` in their terminal; check `klist`. |
| `sqlcmd: command not found` | `mssql-tools18` not installed | `brew bundle check --file=~/.dotfiles/Brewfile.lifetime`; install with `HOMEBREW_ACCEPT_EULA=Y brew install microsoft/mssql-release/msodbcsql18 microsoft/mssql-release/mssql-tools18`. |
| Hang with no output | Brew install waiting for a sudo password (pkg installer) | Ask the user to run the install in their own terminal (`!` prefix). |

## Reporting

2–4 lines: the server and database used, whether the connection and read succeeded, and the answer
to the question. Include the exact error text if a step fails.
