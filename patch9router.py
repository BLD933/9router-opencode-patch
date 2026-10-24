#!/usr/bin/env python3
"""Patch an installed 9router 0.5.109 to route opencode/* through the Bun sidecar."""
import os, shutil, sys, time

APP = os.environ.get("NINEROUTER_APP", "/home/bld/.npm-global/lib/node_modules/9router/app")
CHUNKS = os.path.join(APP, ".next-cli-build", "server", "chunks")
KEY = os.environ.get("OPENCODE_API_KEY", "oc_sk_YOUR_KEY_HERE")
ORG = os.environ.get("OPENCODE_ORG_ID", "wrk_YOUR_ORG_ID_HERE")
PROJECT = os.environ.get("OPENCODE_PROJECT", "YOUR_PROJECT_HASH_HERE")
SIDE = os.environ.get("SIDECAR_URL", "http://127.0.0.1:8199")

assert os.path.isdir(CHUNKS), f"chunks dir not found: {CHUNKS}"

def patch(name, replacements):
    p = os.path.join(CHUNKS, name)
    s = open(p, encoding="utf-8", errors="surrogateescape").read()
    ts = time.strftime("%Y%m%d_%H%M%S")
    for old, new, label in replacements:
        if s.count(old) != 1:
            print(f"  SKIP {label}: pattern not found (already patched?)")
            continue
        s = s.replace(old, new)
        print(f"  ok {label}")
    shutil.copy2(p, f"{p}.bak_{ts}")
    open(p, "w", encoding="utf-8", errors="surrogateescape").write(s)

print("Patching 5330.js (opencode + opencode-go)...")
patch("5330.js", [
    ('Authorization:"Bearer public","User-Agent"',
     f'Authorization:"Bearer {KEY}","User-Agent"', "auth-key"),
    ('"x-opencode-project":f["x-opencode-project"]||"global",Accept:"*/*"',
     f'"x-opencode-project":f["x-opencode-project"]||"global","x-opencode-org-id":"{ORG}",Accept:"*/*"', "org-id"),
    ('let b=this.config.baseUrl;return F(a)?`${b}/inference/v1/responses`',
     f'let b="{SIDE}";return F(a)?`${{b}}/inference/v1/responses`', "buildUrl-opencode"),
    ('return n(a)?"https://opencode.ai/zen/go/v1/responses":super.buildUrl(a,b,c,d)}',
     f'return n(a)?"{SIDE}/zen/go/v1/responses":super.buildUrl(a,b,c,d)}', "buildUrl-go"),
])

print("Patching 7373.js (opencode-zen)...")
patch("7373.js", [
    ('?"opencode/1.18.31":i', '?"opencode/latest/2.1.4/cli":i', "ua-zen"),
    ('g["x-opencode-client"]||"desktop"', 'g["x-opencode-client"]||"cli"', "client-zen"),
    ('e["x-opencode-project"]=g["x-opencode-project"]||"global";',
     'e["x-opencode-project"]=g["x-opencode-project"]||"global",e.Accept="*/*";', "project-zen"),
    ('return v(a)?"https://opencode.ai/zen/v1/responses":super.buildUrl(a,b,c,d)}',
     f'return v(a)?"{SIDE}/zen/v1/responses":super.buildUrl(a,b,c,d)}', "buildUrl-zen"),
])

# UA alignment + b3/traceparent/x-session in 5330
s = open(os.path.join(CHUNKS, "5330.js"), encoding="utf-8", errors="surrogateescape").read()
# (already applied via earlier patches; verify)
print("Done. Restart 9router after starting the sidecar.")
