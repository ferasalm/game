# OpenCode CLI Setup for Qarnaw

Official docs: https://opencode.ai/docs | GitHub: https://github.com/anomalyco/opencode | OpenRouter: https://openrouter.ai/docs

## 1. Windows Installation & Free Models
- Install commands (requires Node.js >= 18.0.0 for npm; verify with `node -v`):
  - npm: `npm install -g opencode-ai`
  - scoop: `scoop install opencode`
  - installer: Windows `.exe` setup from https://opencode.ai/download
- Check version: `opencode --version`
- Accounts / Sign-in:
  - Built-in free models: No account or sign-in needed out of the box.
  - OpenCode Zen: Requires sign-in / API key via `opencode` -> `/connect` -> OpenCode Zen.
  - OpenRouter: Requires OpenRouter API key configured via `/connect` or `OPENROUTER_API_KEY`.
- Free providers for GLM 5.3 Flash & DeepSeek V4.1 Flash:
  - OpenCode Zen: Free-tier promotional models (`opencode/glm-5.3-flash`, `opencode/deepseek-v4.1-flash`; also tagged with `-free` suffixes).
  - OpenRouter: Free endpoints with `:free` suffix (`openrouter/z-ai/glm-5.3-flash:free` [UNVERIFIED: current exact slug], `openrouter/deepseek/deepseek-v4.1-flash:free` or `openrouter/deepseek/deepseek-chat:free`).
  - Model makers' official APIs (Zhipu AI, DeepSeek): Paid pay-as-you-go APIs only; no continuous free production API tiers.
- Rate limits:
  - OpenRouter `:free`: 20 requests/min (RPM). Daily cap: 50 requests/day (<$10 lifetime credit purchase) or 1,000 requests/day (>=$10).
  - OpenCode Zen free tier: Dynamic rate limits and concurrency throttling during peak traffic; removed on paid or Go plan ($10/mo).
- Prompt training (Plain disclosure):
  - OpenCode Zen: Paid models follow Zero Data Retention (ZDR). Free/promotional models explicitly state prompts MAY be used for model training and evaluation.
  - OpenRouter: Free tier (`:free`) routes to providers that MAY retain and train on prompts unless your OpenRouter account privacy settings explicitly opt out.

## 2. Configuration (`opencode.json`)
- Locations: Project root (`./opencode.json` or `./.opencode/opencode.json`) takes precedence over user global config (`~/.config/opencode/opencode.json`).
- Minimal repo configuration for Qarnaw:
```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "opencode/glm-5.3-flash",
  "instructions": [
    "GEMINI.md"
  ],
  "permission": {
    "shell": "allow",
    "edit": "allow"
  }
}
```

## 3. Rules & Instructions
- Precedence:
  1. `AGENTS.md` at workspace root is OpenCode's primary project rule file.
  2. Fallback: `CLAUDE.md` is loaded ONLY if `AGENTS.md` does NOT exist.
  3. Additional rules can be added via the `instructions` array in `opencode.json`.
- Recommendation: Create a 1-line root `AGENTS.md` pointing to `GEMINI.md` (e.g. `See GEMINI.md for repo rules and builder constraints.`).
  - Rationale: Having `AGENTS.md` prevents OpenCode from falling back to `CLAUDE.md` (which contains Claude-specific orchestrator rules), while `"instructions": ["GEMINI.md"]` in `opencode.json` ensures full standing builder rules are loaded.

## 4. Skills Compatibility
- Discovery: OpenCode natively scans `.opencode/skills/*/SKILL.md` and supports compatibility paths `.claude/skills/*/SKILL.md` and `~/.agents/skills/*/SKILL.md`.
- Version added: Added in OpenCode V2 (CLI v0.2.0 [UNVERIFIED: exact patch version]).
- Additional paths: Register custom skill folders via `"skills": [".agents/skills"]` in `opencode.json`.
- Fallback: If skills fail to trigger, include the skill file path in `opencode.json` `"instructions"` or paste relevant skill rules directly into the task brief.

## 5. Non-Interactive Runs (`opencode run`)
- CLI Flags:
  - `--model <id>` / `-m`: Select model.
  - `--auto`: Auto-approves permissions (shell, edit) not explicitly denied.
  - `--format <format>`: Output format (`text` [default] or `json`).
  - Working directory: OpenCode executes in the current working directory (`cd <dir>`).
  - Timeout: No native CLI `--timeout` flag (network/MCP timeouts are configured in `opencode.json`). Enforce task timeout via Git Bash `timeout`.
  - Exit code: 0 on success, non-zero on failure.
- Git Bash example command:
```bash
cd <worktree> && timeout 90m opencode run --model opencode/glm-5.3-flash --auto "$(cat brief.md)" > log 2>&1
```

## 6. Known Windows Issues & Fixes
- Paths: Backslashes in paths cause parsing issues. Fix: Use forward slashes (`/`); set `MSYS_NO_PATHCONV=1` in Git Bash if MSYS alters paths.
- Process termination: Spawning bash on Windows can leave orphan processes on kill (GitHub #24501). Fix: Terminate via `taskkill //F //T //PID <pid>`.
- Line endings (CRLF vs LF): Tool edits may mangle CRLF/LF (GitHub #18616, #6348). Fix: Ensure `.gitattributes` has `* text=auto eol=lf` or set `git config core.autocrlf false`.
- Tool timeouts: OpenCode's default bash tool timeout (1m-5m, GitHub #1721) can interrupt long tasks (e.g. Godot imports). Fix: Configure tool timeouts in `opencode.json` or keep steps granular.

## 7. Commands for the Owner
```bash
# 1. Install OpenCode CLI globally (requires Node 18+)
npm install -g opencode-ai

# 2. Check installation
opencode --version

# 3. (Optional) OpenRouter (verified 2026-10-23 with CLI 1.19.4): the CLI keeps its own data folder (tools/oc_task.sh),
#    so log in with the same XDG_DATA_HOME; the key lands in ~/.local/share/oc-cli/opencode/auth.json (outside the repo).
#    The owner types the key himself; Claude never types or stores it.
XDG_DATA_HOME="$HOME/.local/share/oc-cli" opencode auth login   # pick OpenRouter, paste the key
XDG_DATA_HOME="$HOME/.local/share/oc-cli" opencode auth list    # shows 1 credential
XDG_DATA_HOME="$HOME/.local/share/oc-cli" opencode models openrouter | grep ':free'
```
