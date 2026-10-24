#!/usr/bin/env bash
set -e
: "${OPENCODE_API_KEY:?set OPENCODE_API_KEY=oc_sk_...}"
: "${OPENCODE_ORG_ID:?set OPENCODE_ORG_ID=wrk_...}"
export OPENCODE_PROJECT="${OPENCODE_PROJECT:-YOUR_PROJECT_HASH_HERE}"
DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$DIR/patch9router.py"
# start sidecar
if ! ss -ltn 2>/dev/null | grep -q ':8199 '; then
  setsid nohup ~/.bun/bin/bun "$DIR/ocside.mjs" > "$DIR/ocside.log" 2>&1 < /dev/null &
  sleep 3
  cat "$DIR/ocside.log"
fi
echo "Now start 9router: 9router -t -n --skip-update"
