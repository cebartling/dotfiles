---
name: maven-auth
description: Update the network (Nexus) password that Maven uses in ~/.m2/settings.xml, and diagnose Maven problems such as 401/403 authentication failures, SSL/PKIX errors, unresolvable dependencies, and a missing or mismatched Maven/Java setup. Use when the user says "update my Maven password", "Maven 401", "Maven can't download dependencies", "my network password changed", "diagnose Maven", or invokes /maven-auth.
---

# Maven auth and diagnostics

Maven talks to the LTF Nexus at `nexus.lifetime.life` using the username and
password in `~/.m2/settings.xml`. The three `<server>` entries (`nexus`,
`ltf-releases`, `ltf-snapshots`) share one username and one password. Each
password is Maven-encrypted (`{...}`), with the master key in
`~/.m2/settings-security.xml`.

Never ask for the password in chat, never put it in a command line or argument,
and never print it. Nothing below needs the plaintext.

## Rules

- **Diagnose first.** Run the read-only checks in step 1 before changing anything.
- **Never retry a bad password in a loop.** AD-backed accounts can lock after a few failures. Make at most one authenticated attempt per run, then report.
- **Back up before editing.** Copy `settings.xml` to `settings.xml.backup.<timestamp>`, as the linkers in this repo do.
- **Do not commit or push** anything from this skill. `settings.xml` lives outside the dotfiles repo.

## 1. Diagnose (read-only)

Find the Maven binary. Use `mvn` if it is on PATH, otherwise the wrapper copy:

```bash
MVN=$(command -v mvn || find ~/.m2/wrapper/dists -path '*/bin/mvn' -type f | sort | tail -1)
echo "mvn: $MVN"; "$MVN" -v 2>&1 | head -3
java -version 2>&1 | head -1
```

Check the settings file and its wiring:

```bash
xmllint --noout ~/.m2/settings.xml && echo "settings.xml: well-formed"
ls -l ~/.m2/settings-security.xml        # master key must exist
# Server ids referenced by repositories/mirrors must have a <server> entry
grep -oE '<id>[^<]+</id>' ~/.m2/settings.xml | sort | uniq -c
# Password format only, no values: '{' = encrypted, anything else = plaintext (warn)
awk '/<server>/{s=1} s&&/<id>/{id=$0} s&&/<password>/{v=$0; sub(/.*<password>/,"",v); sub(/<\/password>.*/,"",v); print id" -> "(substr(v,1,1)=="{" ? "encrypted" : "PLAINTEXT (warn)"); s=0}' ~/.m2/settings.xml
```

Check Nexus reachability. This request sends no credentials, so it cannot lock anything:

```bash
curl -s -o /dev/null -m 15 -w 'nexus unauth: HTTP %{http_code}\n' https://nexus.lifetime.life/service/rest/v1/status
```

- If this fails with a DNS error, check VPN. If it fails with an SSL or PKIX error, see the table below.

Check for stale resolver state, which causes "cached failure" errors even after a password is fixed:

```bash
find ~/.m2/repository -name 'resolver-status.properties' -o -name '*.lastUpdated' 2>/dev/null | wc -l
```

### Symptom → cause

| Symptom in Maven output | Likely cause | Fix |
|---|---|---|
| `401 Unauthorized` on nexus / ltf-* | Password changed or expired; server id mismatch | Step 2 |
| `403 Forbidden` | Account is valid but lacks the role, or is locked | Check the account in Nexus web UI, then escalate |
| `Could not transfer metadata ... was cached in the local repository` | Stale `resolver-status.properties` / `.lastUpdated` after an earlier failure | Re-run with `-U`; delete the `*.lastUpdated` files for that artifact |
| `PKIX path building failed` / `unable to find valid certification path` | Corporate CA missing from the JDK truststore | Import the CA into the JDK `cacerts` |
| `Unknown host` / `Connection timed out` | DNS, VPN, or proxy | Check VPN and proxy settings |
| `Non-parseable POM` / `Unsupported class file major version` | Maven or JDK mismatch with the project | Check `java -version` against the project's required version |
| `mvn: command not found` | Maven not on PATH | Use the wrapper binary from step 1 |

### Auth check (one attempt, do this once)

Use a throwaway local repository so a cached artifact cannot hide an auth failure:

```bash
REPO=$(mktemp -d "$HOME/.m2/auth-check.XXXX")
"$MVN" -B -U -Dmaven.repo.local="$REPO" -Dtransitive=false \
  dependency:get -Dartifact=commons-codec:commons-codec:1.16.1
rm -rf "$REPO"
```

Read the result:

- `BUILD SUCCESS` with the real settings: the password works, **provided anonymous reads are blocked**. Confirm that by running the same command with a copy of settings that has no `<servers>` (for example `-s ~/.m2/settings-anon.xml`, then delete it). If the anonymous run also succeeds, this check proves nothing. Say so, and confirm the login in the Nexus web UI instead.
- `401` / `403` in the output: the password is wrong or expired. Go to step 2.

## 2. Update the password

Stop here if step 1 showed the password is fine.

### 2a. Encrypt the new password (user does this in their own terminal)

Tell the user to run this in their terminal with the `!` prefix, so the prompt is hidden and the output goes to a file, not the chat. Substitute the `MVN` path resolved in step 1:

```
! umask 077 && "<MVN path>" --encrypt-password > ~/.m2/.new-pass.enc
```

Maven prompts for the password on the TTY. The user types the new network password, and nothing echoes. Maven writes the `{...}` encrypted value to `~/.m2/.new-pass.enc`. Do not ask the user to paste the password or the encrypted value into chat.

Then verify the file holds a single encrypted value, without printing it:

```bash
f=~/.m2/.new-pass.enc
[ -s "$f" ] && [ "$(wc -l < "$f" | tr -d ' ')" -le 1 ] && head -c1 "$f" | grep -q '{' && echo "encrypted value: ok" || echo "encrypted value: BAD (re-run 2a)"
```

If it is not ok, ask the user to run 2a again. Do not guess.

### 2b. Replace the password in the three server entries

```bash
set -e
cp ~/.m2/settings.xml ~/.m2/settings.xml.backup.$(date +%Y%m%d-%H%M%S)
NEW="$(cat ~/.m2/.new-pass.enc)" awk '
  /<id>(nexus|ltf-releases|ltf-snapshots)<\/id>/ { inid=1 }
  inid && /<password>/ {
    sub(/<password>[^<]*<\/password>/, "<password>" ENVIRON["NEW"] "</password>")
    inid=0
  }
  { print }
' ~/.m2/settings.xml > ~/.m2/settings.xml.new
mv ~/.m2/settings.xml.new ~/.m2/settings.xml
rm -f ~/.m2/.new-pass.enc
xmllint --noout ~/.m2/settings.xml && echo "settings.xml updated and well-formed"
```

The password is passed through the environment, not argv. The encrypted file is deleted afterwards.

Then check that all three entries changed and none is plaintext. Rerun the format check from step 1. It should print `encrypted` three times.

### 2c. Verify

Run the auth check from step 1 once. Report the result. If it is still `401`, the new password was not accepted. Tell the user, and do not retry.

## Reporting

Report what was checked and what changed, with the actual output. For example:

- `mvn: ... (3.9.11)`, `java: ...`
- `nexus unauth: HTTP 200`
- `auth check: BUILD SUCCESS` or the exact `401` line
- which backup file was written

If a step could not be verified, say so plainly and name the step.
