# trisatya.dev

My portfolio and build log. Astro 7, built into an Nginx image, deployed to my
VPS by GitHub Actions with a health check and automatic rollback.

## Develop

Astro 7 needs Node >= 22.23. Without that locally, run it in a container:

```bash
docker run --rm -it -v "$PWD:/w" -w /w -p 4321:4321 node:24-alpine \
  sh -c "npm ci && npx astro dev --host"
```

Write a post: add `src/content/blog/<slug>.md` with `title`, `description`,
`pubDate` (and optional `tags`, `draft: true`). Site text lives in
`src/consts.ts`.

## Live status

The service cards and the host strip read `/status/status.json`, written every
minute on the VPS by `scripts/status.sh` (cron) into `~/trisatya.dev/status/`,
which the container serves read-only. It probes the same health endpoints the
deploy scripts use. Without the file (local dev), the page shows
"status unavailable".

## Deploy

Push to `main`: shellcheck, `nginx -t` on the host config, image build to
`ghcr.io/trisatyaelisa-dev/trisatya.dev:<sha>`, then `scripts/deploy.sh` on the
VPS over a restricted SSH key (`command=".../deploy.sh",restrict`), with
rollback if `http://127.0.0.1:8081/` stops serving the page.

Host Nginx changes (`nginx/trisatya.dev.conf`) need a manual
`sudo nginx -t && sudo systemctl reload nginx`. Certificates:
`sudo certbot certonly --nginx -d trisatya.dev` (never `certbot --nginx`).
