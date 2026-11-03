#!/usr/bin/env python3
"""Every model a builder may call is on a free provider (Feras 11-04: Cloudflare billed $32.29 on a lane with no cap).
Reads tools/free_providers.txt and checks the model slugs in builders.conf and both opencode configs, plus the
opencode configs' provider blocks: a paid provider fails here before any run can spend."""
import json
import os
import re

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
PROVIDERS = ("nvidia", "cerebras", "groq", "google", "opencode", "openrouter", "cloudflare-workers-ai",
             "cloudflare-ai-gateway", "anthropic", "openai", "deepseek", "zai", "mistral", "xai", "together", "fireworks")


def rules():
    out = []
    for line in open(os.path.join(TOOLS, "free_providers.txt"), encoding="utf-8"):
        line = line.split("#", 1)[0].split()
        if line:
            out.append((line[0], line[1] if len(line) > 1 else ""))
    return out


def allowed(slug, rs):
    return any(slug.startswith(p) and slug.endswith(s) for p, s in rs)


def conf_slugs(text):
    """Model slugs in builders.conf default values: a provider name, a slash, an id."""
    found = []
    for line in text.splitlines():
        m = re.match(r'\s*:\s*"\$\{(\w+):=(.*)\}"', line)
        if not m or "MODEL" not in m.group(1) and m.group(1) not in ("NV_CHAIN",) and not m.group(1).startswith("XR_REVIEWER"):
            continue
        for tok in m.group(2).split():
            if "/" in tok and tok.split("/", 1)[0] in PROVIDERS:
                found.append(tok)
    return found


def test_the_allowlist_has_no_paid_provider():
    rs = rules()
    assert rs and not any(p.startswith("cloudflare") for p, _ in rs), rs


def test_builders_conf_names_only_free_models():
    rs = rules()
    slugs = conf_slugs(open(os.path.join(TOOLS, "builders.conf"), encoding="utf-8").read())
    assert len(slugs) >= 5, slugs  # NV_MODEL, the chain and the reviewers: a parse that finds nothing proves nothing
    bad = [s for s in slugs if not allowed(s, rs)]
    assert not bad, f"paid or unlisted model in builders.conf: {bad} (tools/free_providers.txt)"


def test_opencode_configs_hold_only_free_providers():
    rs = rules()
    for rel in ("opencode.json", "tools/cross_review.opencode.json"):
        cfg = json.load(open(os.path.join(ROOT, rel), encoding="utf-8"))
        for key in ("model", "small_model"):
            if key in cfg:
                assert allowed(cfg[key], rs), f"{rel} {key}={cfg[key]} is not free"
        for prov in cfg.get("provider", {}):
            assert any(p.rstrip("/") == prov for p, _ in rs), f"{rel} configures provider {prov}: not in free_providers.txt"


def test_a_paid_slug_is_caught():  # probe the rule with one bad case (LESSONS 3)
    rs = rules()
    assert not allowed("cloudflare-workers-ai/@cf/deepseek-ai/deepseek-v4.1-flash-1017", rs)
    assert not allowed("openrouter/anthropic/claude-opus", rs) and not allowed("opencode/gpt-5", rs)
    assert allowed("openrouter/nvidia/nemotron-3-ultra-550b-a55b:free", rs) and allowed("opencode/glm-5.3-flash-free", rs)
    assert conf_slugs(': "${NV_MODEL:=cloudflare-workers-ai/x}"') == ["cloudflare-workers-ai/x"]


if __name__ == "__main__":
    from tool_tests import run_cases
    run_cases([v for k, v in sorted(globals().items()) if k.startswith("test_")], "test_free_providers")
