import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
const DIR = dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.SIDECAR_PORT || 8199);
const UP = "https://opencode.ai";
const TPL = JSON.parse(readFileSync(join(DIR, "oc_template.json"), "utf8"));
const FIXED = JSON.parse(readFileSync(join(DIR, "oc_fixed_headers.json"), "utf8"));
const SYS = TPL.messages.find(m => m.role === "system");
const TOOLS = TPL.tools;

Bun.serve({
  port: PORT,
  async fetch(req) {
    const u = new URL(req.url);
    const target = UP + u.pathname + (u.search || "");
    let body = {};
    try { body = await req.json(); } catch {}
    const incomingMsgs = Array.isArray(body.messages) ? body.messages : [];
    const nonSys = incomingMsgs.filter(m => m && m.role !== "system");
    let msgs = SYS ? [SYS, ...nonSys] : incomingMsgs;
    if (msgs.length === 1 && SYS) msgs = [SYS, { role: "user", content: "hi" }];
    const out = {
      model: TPL.model,
      messages: msgs,
      tools: TOOLS,
      stream: body.stream !== false,
      stream_options: TPL.stream_options,
      max_completion_tokens: body.max_tokens || body.max_completion_tokens || TPL.max_completion_tokens,
    };
    const headers = new Headers(FIXED);
    headers.set("host", "opencode.ai");
    headers.set("content-type", "application/json");
    const res = await fetch(target, { method: "POST", headers, body: JSON.stringify(out) });
    const outH = new Headers(res.headers); outH.delete("transfer-encoding");
    return new Response(res.body, { status: res.status, statusText: res.statusText, headers: outH });
  },
});
console.log("ocside up on", PORT);
