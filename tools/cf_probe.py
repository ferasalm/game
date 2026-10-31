#!/usr/bin/env python
"""One timed Workers AI call for model calibration (row 18): time to first token, tokens, speed, finish reason.
The Cloudflare token stays in the environment, never printed. A spend line goes to cf_spend.csv like cf_mcp.
Usage: python tools/cf_probe.py --model @cf/zai-org/glm-5.3-flash --prompt-file p.md [--system-file s.md]
         [--effort none|low|medium|high|max] [--extra '{"temperature": 1}'] [--image frame.png] [--out reply.txt]"""
import argparse
import base64
import json
import sys
import time
import urllib.error
import urllib.request
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "cf_mcp"))
import server  # noqa: E402  (its _env: the token never enters a prompt or a log)

TIMEOUT_S = 900


def build_body(model: str, prompt: str, system: str, effort: str, extra: dict, image: bytes = b"") -> dict:
    user: object = prompt
    if image:
        url = "data:image/png;base64," + base64.b64encode(image).decode()
        user = [{"type": "text", "text": prompt}, {"type": "image_url", "image_url": {"url": url}}]
    messages = ([{"role": "system", "content": system}] if system else []) + [{"role": "user", "content": user}]
    body = {"model": model, "messages": messages, "stream": True, "stream_options": {"include_usage": True}}
    if effort:
        body["reasoning_effort"] = effort
    body.update(extra)
    return body


def read_stream(lines, clock=time.monotonic) -> dict:
    """Folds an OpenAI-style SSE stream of bytes lines into timings, text and usage."""
    start = clock()
    out = {"first_thought_s": None, "first_text_s": None, "text": "", "thought_chars": 0, "finish": "", "usage": {},
           "bad_lines": 0, "stop_chunks": 0}
    for raw in lines:
        line = raw.decode("utf-8", errors="replace").strip()
        if not line.startswith("data:") or line.endswith("[DONE]"):
            continue
        try:
            event = json.loads(line[5:])
        except json.JSONDecodeError:
            out["bad_lines"] += 1
            continue
        out["usage"] = event.get("usage") or out["usage"]
        for choice in event.get("choices", []):
            delta = choice.get("delta") or {}
            thought = delta.get("reasoning_content") or delta.get("reasoning") or ""
            if thought:
                out["thought_chars"] += len(thought)
                if out["first_thought_s"] is None:
                    out["first_thought_s"] = round(clock() - start, 2)
            if delta.get("content"):
                out["text"] += delta["content"]
                if out["first_text_s"] is None:
                    out["first_text_s"] = round(clock() - start, 2)
            out["finish"] = choice.get("finish_reason") or out["finish"]
            out["stop_chunks"] += 1 if choice.get("finish_reason") else 0
    out["total_s"] = round(clock() - start, 2)
    return out


def was_cut(r: dict) -> bool:
    """The literal end marker in a reply or a thought ends the direct stream early with finish "stop" and a whole-looking
    usage. A whole stream carries two finish chunks, a cut one carries one (row 18c, none and max; opencode is not hit)."""
    return r["finish"] == "stop" and r["stop_chunks"] < 2


def summary(model: str, effort: str, r: dict) -> dict:
    usage = r["usage"]
    details = usage.get("completion_tokens_details") or {}
    done = usage.get("completion_tokens", 0)
    return {"model": model, "effort": effort or "default", "first_text_s": r["first_text_s"],
            "first_thought_s": r["first_thought_s"], "total_s": r["total_s"], "in": usage.get("prompt_tokens"),
            "out": done, "reasoning_tokens": details.get("reasoning_tokens"), "thought_chars": r["thought_chars"],
            "text_chars": len(r["text"]), "tok_s": round(done / r["total_s"], 1) if r["total_s"] else 0,
            "finish": r["finish"], "bad_lines": r["bad_lines"], "cut": was_cut(r)}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True)
    ap.add_argument("--prompt-file", required=True)
    ap.add_argument("--system-file", default="")
    ap.add_argument("--effort", default="")
    ap.add_argument("--extra", default="{}")
    ap.add_argument("--image", default="")
    ap.add_argument("--out", default="")
    a = ap.parse_args()
    acct, token = server._env("CLOUDFLARE_ACCOUNT_ID"), server._env("CLOUDFLARE_API_TOKEN")
    if not acct or not token:
        print("ERROR: CLOUDFLARE_ACCOUNT_ID or CLOUDFLARE_API_TOKEN is not set")
        return 1
    system = Path(a.system_file).read_text(encoding="utf-8") if a.system_file else ""
    image = Path(a.image).read_bytes() if a.image else b""
    body = build_body(a.model, Path(a.prompt_file).read_text(encoding="utf-8"), system, a.effort, json.loads(a.extra), image)
    req = urllib.request.Request(server.API.format(acct=acct), data=json.dumps(body).encode(), method="POST",
                                 headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT_S) as resp:
            result = read_stream(resp)
    except urllib.error.HTTPError as e:
        print(f"ERROR: HTTP {e.code}: {e.read()[:500].decode(errors='replace')}")
        return 1
    except (urllib.error.URLError, TimeoutError) as e:
        print(f"ERROR: {e}")
        return 1
    print(json.dumps(summary(a.model, a.effort, result)), flush=True)  # first: a paid result survives any failure below
    if a.out:
        Path(a.out).write_text(result["text"], encoding="utf-8", newline="\n")
    usage = result["usage"]
    with server.SPEND_LOG.open("a", encoding="utf-8", newline="\n") as f:
        f.write(f"{date.today()},cf_probe,{usage.get('prompt_tokens', '')},{usage.get('completion_tokens', '')},{a.model}\n")
    if was_cut(result):
        print("ERROR: the stream was cut (one finish chunk): the reply is incomplete")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
