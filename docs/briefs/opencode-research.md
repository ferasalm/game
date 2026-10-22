# Brief: opencode-research (research only; <= 60 lines)
You are in your own worktree on branch gemini/opencode-research (made from claude/night-sanaa). Follow GEMINI.md.
This task writes ONE markdown file and changes no code.

## Why
The owner wants the opencode CLI (sst/opencode, npm package `opencode-ai`) as a second cheap builder beside agy,
using free models: GLM 5.3 Flash and DeepSeek V4.1 Flash. Claude will run it non-interactively from Git Bash on
Windows 11, one git worktree per task, the way tools/agy_task.sh runs agy.

## Read first
tools/agy_task.sh, tools/agy_review.sh, GEMINI.md (first 30 lines), docs/EFFICIENCY.md section 3b.
Then search the web: the official opencode docs (opencode.ai/docs: install, config, models, providers, rules,
agents, skills, permissions, CLI `run`), its GitHub README and releases. Prefer official pages; note each URL.

## What to write: docs/research/opencode-setup.md (<= 120 lines)
1. Install on Windows (npm, scoop, or installer): the exact commands, the minimum Node version, how to check the
   version. Is a sign-in or account needed for free models? Which provider gives GLM 5.3 Flash and DeepSeek V4.1
   Flash for free (opencode Zen free tier, OpenRouter `:free`, the model makers' own APIs)? Exact model id strings
   as `provider/model`, rate limits, and whether prompts may be used for training (say so plainly).
2. Config: where `opencode.json` lives (project root vs global), a complete minimal example for this repo that
   sets the default model, allows edit and bash without prompts, and points at the rules files.
3. Rules: does opencode read AGENTS.md, CLAUDE.md, or both, and in which order? How to add extra instruction
   files (the `instructions` field). Recommend: a short AGENTS.md that points at GEMINI.md, or reuse GEMINI.md.
4. Skills: does opencode load `.claude/skills/*/SKILL.md` or `.agents/skills/*/SKILL.md`? Which version added it?
   If not supported, how to give a skill to it (instructions field, or paste into the brief).
5. Non-interactive runs: the exact `opencode run` flags for a one-shot prompt with a chosen model, a working
   directory, auto-approved permissions, a timeout, and the exit code / output format (text vs json). Show one full
   example command for Git Bash: `cd <worktree> && opencode run --model <id> "$(cat brief.md)" > log 2>&1`.
6. Known Windows problems (paths, Git Bash, line endings, long runs being cut off) and their fixes.
7. A "commands for the owner" block: only the install and sign-in steps a human must do, in order.
Mark every fact you could not confirm from an official page as UNVERIFIED. Never invent version numbers or ids.

## Do NOT edit
Anything except docs/research/opencode-setup.md. Do not install anything, sign in, or create accounts.

## Tests
None (a doc). Do not run tools/check.sh.

## Proof
Commit the file; final message lists the URLs used and ends with `Built-by: Gemini 3.8 Flash (agy)`.
