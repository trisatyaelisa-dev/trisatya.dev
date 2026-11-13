#!/usr/bin/env bash
# Writes status/status.json for the home page: the health of each service on
# this host (same endpoints the deploy scripts use) plus a few host numbers.
# Runs every minute from the trisatya crontab; the web container serves the
# file read-only at /status/status.json.

set -euo pipefail

OUT_DIR="${OUT_DIR:-$HOME/trisatya.dev/status}"
mkdir -p "$OUT_DIR"

# probe NAME URL PATTERN -> "NAME OK MS"
probe() {
  local name="$1" url="$2" pat="$3" out ms
  if ! out="$(curl -fsS --max-time 4 -w '\n%{time_total}' "$url" 2>/dev/null)"; then
    echo "$name 0 0"
    return
  fi
  ms="$(printf '%s\n' "$out" | tail -n 1 | awk '{ printf "%d", $1 * 1000 }')"
  if printf '%s\n' "$out" | grep -q "$pat"; then echo "$name 1 $ms"; else echo "$name 0 $ms"; fi
}

probes="$(
  probe grafana   http://127.0.0.1:3000/api/health '"database": *"ok"'
  probe keycloak  http://127.0.0.1:9100/health/ready '"status": *"UP"'
  probe workbench http://127.0.0.1:8080/.well-known/oauth-protected-resource '"resource"'
)"
containers="$(docker ps -q | wc -l | tr -d ' ')"

PROBES="$probes" CONTAINERS="$containers" python3 -I - "$OUT_DIR" <<'PY'
import json, os, sys, datetime

out_dir = sys.argv[1]
services = {}
for line in os.environ["PROBES"].splitlines():
    name, ok, ms = line.split()
    services[name] = {"ok": ok == "1", "ms": int(ms)}

with open("/proc/uptime") as f:
    uptime = int(float(f.read().split()[0]))
mem = {}
with open("/proc/meminfo") as f:
    for line in f:
        k, v = line.split(":")
        mem[k] = int(v.split()[0])
used_pct = round(100 * (mem["MemTotal"] - mem["MemAvailable"]) / mem["MemTotal"])
with open("/proc/loadavg") as f:
    load1 = float(f.read().split()[0])

doc = {
    "updated_at": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "host": {
        "uptime_s": uptime,
        "mem_used_pct": used_pct,
        "load1": load1,
        "containers": int(os.environ["CONTAINERS"]),
    },
    "services": services,
}
tmp = os.path.join(out_dir, ".status.json.tmp")
with open(tmp, "w") as f:
    json.dump(doc, f, separators=(",", ":"))
os.chmod(tmp, 0o644)
os.replace(tmp, os.path.join(out_dir, "status.json"))
PY
