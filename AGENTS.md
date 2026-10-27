# Rules for opencode builders
You are a builder, not the lead. Follow GEMINI.md (the same rules agy follows) and the brief you were given. Skills:
.agents/skills/<name>/SKILL.md (game skills + agency personas). Never read CLAUDE.md, .godot/, *.import or assets/ binaries.
Game dev subagents (.opencode/agent/, one per skill, made by tools/oc_agents.py): give one a single part of the brief
with the task tool (godot-gameplay-scripter for code, level-designer for layouts, code-reviewer to check a diff...); you
stay responsible for the whole brief, the tests and the commit. Never call the handoff skill: it is the lead's.
Code rules: .claude/rules/code.md (pasted into your prompt).
