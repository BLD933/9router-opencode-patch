# 9router → OpenCode free lane patch

Makes 9router's `opencode/*` models actually return 200 instead of 429.

## Why

The OpenCode free lane (`opencode.ai`) is attested at three layers:
1. **Transport** — only Bun's TLS/HTTP2 stack passes. Node (9router's runtime) gets 429; curl gets 403.
2. **Headers** — needs `b3`, `traceparent`, `x-opencode-org-id`, the real `x-opencode-project` hash, `x-session-*`, `x-opencode-session*`, `x-opencode-client: cli`, UA `opencode/latest/2.1.4/cli`, `Accept: */*`, and **no** `x-opencode-request`.
3. **Body** — needs the full OpenCode system prompt + 12 tool definitions (~240KB). 9router's trimmed request body gets 429 even through Bun.

So 9router can't satisfy the gate by itself. This patch routes its opencode requests through a small **Bun sidecar** that replays the captured OpenCode fingerprint (headers + body + Bun transport).

## Requirements
- 9router 0.5.109 installed (`npm i -g 9router@0.5.109`)
- Bun (`curl -fsSL https://bun.sh/install | bash`)
- An OpenCode API key (`oc_sk_...`) from https://opencode.ai

## Install
```bash
export OPENCODE_API_KEY=oc_sk_your_key_here
export OPENCODE_ORG_ID=wrk_your_org_id_here   # from https://opencode.ai/console/api/v2/config
bash install.sh
```

## Files
- `patch9router.py` — patches the installed 9router chunks (headers, key, org id, buildUrl → sidecar)
- `ocside.mjs` — Bun sidecar (port 8199) that forwards with the OpenCode fingerprint
- `oc_template.json` — captured OpenCode request body (system prompt + tools)
- `oc_fixed_headers.json` — captured OpenCode headers (key/org/project replaced with placeholders)
- `install.sh` — runs patch + starts sidecar + 9router

## Notes
- `oc_template.json` contains OpenCode's own system prompt (public, from the MIT-licensed CLI).
- Replace placeholder values in `oc_fixed_headers.json` with your own captured headers if needed.
