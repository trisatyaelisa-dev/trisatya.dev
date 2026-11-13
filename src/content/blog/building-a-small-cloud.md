---
title: 'Building a small cloud on one VPS'
description: 'Keycloak, Grafana and an MCP workbench on a 2 vCPU machine, deployed by GitHub Actions with automatic rollback. And the three things that broke.'
pubDate: '2026-11-13'
tags: ['vps', 'keycloak', 'grafana', 'github-actions']
---

I wanted to understand what happens after `git push`: where the code goes, who
is allowed to log in, what the logs say when something breaks, and how I get
my data back. So I rented a small VPS and built the whole path myself.

## The pieces

| Piece | What it does |
|---|---|
| Cloudflare | DNS and proxy in front of every subdomain, hides the server's IP |
| Nginx + Let's Encrypt | TLS termination, one config file per site, kept in git |
| Keycloak 26 + PostgreSQL 18 | single sign-on for everything below, OTP for admins |
| Grafana, Prometheus, Loki, Alloy | dashboards, metrics and logs from every container |
| workbench | a self-hosted MCP tool aggregator, signing in through Keycloak |
| This site | Astro, built into an Nginx image |

Each piece lives in its own repository and runs with Docker Compose. Nothing
listens on a public port except Nginx; every container binds to `127.0.0.1`.

## How a change reaches the server

Every repository ships the same way:

1. `git push` to `main`.
2. A **check** job validates the Compose file, runs `nginx -t` against the site
   config and `shellcheck` against the scripts.
3. For apps, a **build** job pushes a Docker image to ghcr.io, tagged with the
   commit SHA.
4. A **deploy** job SSHes into the VPS. The key it uses is pinned in
   `authorized_keys` with `command="…/deploy.sh",restrict`, so it can run the
   deploy script and nothing else, not even a shell.
5. `deploy.sh` resets the checkout to that commit, runs `docker compose up -d`,
   and polls the service's health endpoint.
6. If the health check fails, it resets to the previous commit and starts that
   again. The workflow goes red and I get an email, but the site stays up.

I tested the rollback on purpose by pushing a broken config. The server went
back to the last good commit by itself, and I fixed `main` with `git revert`.

## Three things that broke

**A secret with an invisible character.** The first deploy failed with
`Permission denied (publickey)`, even though the key was right. I added a debug
step that printed the key's fingerprint and the *length* of the username
secret: 9, for an 8-letter name. A trailing newline had come along with the
paste. The workflow now strips whitespace from those secrets.

**certbot versus `git reset --hard`.** I keep each Nginx site file in its repo
and symlink it into `/etc/nginx/sites-enabled/`. `certbot --nginx` edits that
file in place to add the TLS block, and the next deploy's `git reset --hard`
quietly removed it again. Nothing broke until Nginx reloaded for an unrelated
change, and then one subdomain started serving a different site. The fix was
to write the TLS block into the repo myself and only ever use
`certbot certonly`. CI now tests the config with throwaway certificates.

**Keycloak's admin console behind a locked door.** I first kept `/admin/` and
the master realm off the public internet and reached them through an SSH
tunnel. The console then failed with *"Timeout when waiting for 3rd party check
iframe message"*: it loaded a session-check iframe from the public hostname,
which my own Nginx blocked. Setting the master realm's frontend URL to the
tunnel address fixed it. Later I opened the console publicly, but only after
turning on OTP and brute-force detection.

## Backups that I have actually restored

A backup I have never restored is a guess. Every night a cron job on the VPS
dumps Keycloak's database with `pg_dump`, copies Grafana's and workbench's
SQLite files safely, and packs each with its `.env`. The workbench archive has
to carry its encryption key, or the stored tokens are useless. I restored each
archive into a throwaway container with no network and checked that the realms,
users and OTP credentials were all there.

## What's next

- An off-site copy of the backups, encrypted before it leaves the server.
- Alerts in Grafana when a service goes down or logins start failing.
- Cleaning up old images: the workbench image is 2.5 GB per version.

The status dots on the [home page](/#stack) come from the same health checks
the deploy script uses, refreshed every minute.
