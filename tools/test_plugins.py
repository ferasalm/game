#!/usr/bin/env python3
"""The repo marketplace and the studio plugin stay loadable and consistent (system-v3 row 22, 2026-11-01)."""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import uuid

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import build_gate as bg  # noqa: E402
import test_session_start as tss  # noqa: E402

PLUGIN = os.path.join(ROOT, "plugins", "studio")
AGENTS = ("review-canon", "review-code", "review-cost", "review-feras", "review-market", "review-player",
          "ui-finish-gate-reviewer")
PLUGIN_HOOKS = ("heredoc_guard", "token_handoff", "stop_notify", "instructions-loaded", "loaded.sh")
SETTINGS_HOOKS = ("pre_spend", "review_gate", "session-start")  # a money gate, a review gate and the missing-plugin warning


def load(*parts):
    with open(os.path.join(ROOT, *parts), encoding="utf-8") as f:
        return json.load(f)


def hook_commands(cfg):
    return [h["command"] for entries in cfg["hooks"].values() for e in entries for h in e["hooks"]]


def test_manifests_parse_and_the_marketplace_points_at_the_plugin():
    market = load(".claude-plugin", "marketplace.json")
    assert market["name"] == "neon" and {"studio", "pm"} <= {p["name"] for p in market["plugins"]}, market
    for entry in market["plugins"]:  # every entry, not only studio (11-02 coach audit: pm's manifest was never read)
        plugin = load("plugins", entry["name"], ".claude-plugin", "plugin.json")
        assert plugin["name"] == entry["name"] and re.fullmatch(r"[a-z][a-z0-9-]*", plugin["name"])
        assert entry["source"].startswith("./") and os.path.isdir(os.path.join(ROOT, entry["source"])), entry
        assert plugin["version"] and plugin["description"]


def test_claude_plugin_validate_passes_when_claude_is_installed():
    if not shutil.which("claude") or os.environ.get("CI"):
        print("skip: claude is not on PATH or CI is set")
        return
    for target in ("plugins/studio", "."):
        done = subprocess.run(["claude", "plugin", "validate", target, "--strict"], cwd=ROOT, capture_output=True, text=True,
                              timeout=120, stdin=subprocess.DEVNULL)
        assert done.returncode == 0, (target, done.stdout + done.stderr)


def test_every_path_the_plugin_hooks_name_exists():
    cfg = load("plugins", "studio", "hooks", "hooks.json")
    for cmd in hook_commands(cfg):
        for var, base in (("${CLAUDE_PLUGIN_ROOT}", PLUGIN), ("$CLAUDE_PROJECT_DIR", ROOT)):
            for rel in re.findall(re.escape(var) + r"/([\w./-]+)", cmd):
                assert os.path.exists(os.path.join(base, rel)), (cmd, rel)


def test_every_path_the_settings_hooks_name_exists():  # the cutover moved hooks by hand; a missing script drops one silently
    for cmd in hook_commands(load(".claude", "settings.json")):
        for rel in re.findall(r"\$CLAUDE_PROJECT_DIR/([\w./-]+)", cmd):
            assert os.path.exists(os.path.join(ROOT, rel)), (cmd, rel)
        assert re.findall(r"\$CLAUDE_PROJECT_DIR/", cmd), cmd


def test_plugin_hooks_hold_the_non_safety_hooks_and_settings_keeps_the_safety_ones():
    plugin_cmds = " ".join(hook_commands(load("plugins", "studio", "hooks", "hooks.json")))
    settings_cmds = " ".join(hook_commands(load(".claude", "settings.json")))
    for name in PLUGIN_HOOKS:
        assert name in plugin_cmds, name
        assert name not in settings_cmds, f"{name} runs twice: cut over to the plugin (row 25, 2026-11-01)"
    for name in SETTINGS_HOOKS:  # a plugin that fails to load drops its hooks silently: these must not depend on one
        assert name in settings_cmds and name not in plugin_cmds, name


def test_the_seven_reviewer_agents_live_only_in_the_plugin():
    for name in AGENTS:
        path = os.path.join(PLUGIN, "agents", f"{name}.md")
        text = open(path, encoding="utf-8").read()
        assert re.match(rf"---\n(?:.*\n)*?name: {name}\n(?:.*\n)*?---\n", text) and "description:" in text, name
        assert not os.path.exists(os.path.join(ROOT, ".claude", "agents", f"{name}.md")), f"{name} lives in both places"


def test_no_skill_lives_in_both_the_plugin_and_the_project():
    plugin_skills = os.path.join(PLUGIN, "skills")
    mine = set(os.listdir(plugin_skills)) if os.path.isdir(plugin_skills) else set()
    project = set(os.listdir(os.path.join(ROOT, ".claude", "skills")))
    assert not (mine & project), mine & project


def test_build_gate_protects_plugins_but_allows_new_files():
    hits = bg.protected_hits({"plugins/studio/hooks/hooks.json": "M", "plugins/studio/scripts/new.py": "A"}, [])
    assert hits == ["plugins/studio/hooks/hooks.json"], hits
    assert bg.protected_hits({"plugins/studio/hooks/hooks.json": "M"}, ["plugins/studio/hooks/hooks.json"]) == []


def test_plugin_gdignore_keeps_godot_out_and_plugin_scripts_are_mapped():
    assert os.path.isfile(os.path.join(ROOT, "plugins", ".gdignore"))
    map_text = open(os.path.join(ROOT, "docs", "MAP.md"), encoding="utf-8").read()
    assert "plugins/studio/scripts/loaded.sh" in map_text or "plugins/studio/hooks/hooks.json" in map_text


def session_env(top, session_id):
    return top, dict(os.environ, CLAUDE_PROJECT_DIR=top + "/main", TMPDIR=os.path.join(top, "tmp")), json.dumps({"session_id": session_id})


def test_session_start_warns_in_one_line_when_studio_is_not_loaded():
    top, env, stdin = session_env(tss.repo_with_side_worktree()[0], "s-" + uuid.uuid4().hex)
    os.makedirs(env["TMPDIR"])
    os.makedirs(top + "/side/plugins/studio")
    out = tss.run_hook(top + "/side", env, stdin)
    warns = [ln for ln in out.splitlines() if "plugin studio is not loaded" in ln]
    assert len(warns) == 1, out
    plain = tss.run_hook(top + "/main", env, stdin)  # a checkout without plugins/studio says nothing
    assert "studio" not in plain, plain


def test_loaded_marker_silences_the_warning_and_the_plugin_hook_writes_it():
    sid = "s-" + uuid.uuid4().hex
    top, env, stdin = session_env(tss.repo_with_side_worktree()[0], sid)
    os.makedirs(env["TMPDIR"])
    os.makedirs(top + "/side/plugins/studio")
    done = subprocess.run(["bash", os.path.join(PLUGIN, "scripts", "loaded.sh")], env=env, input=stdin, capture_output=True,
                          text=True, timeout=30)
    assert done.returncode == 0 and os.path.exists(os.path.join(env["TMPDIR"], f"neon-studio-loaded-{sid}")), done.stderr
    out = tss.run_hook(top + "/side", env, stdin)
    assert "not loaded" not in out, out


if __name__ == "__main__":
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_plugins: {len(tests)} tests passed")
