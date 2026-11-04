# Opens a NEW Claude Code chat in its own window with the next-chat prompt (HANDOFF "Prompt for the next chat").
# Run after the previous chat merged and synced C:\dev\game. Usage: pwsh tools\next_chat.ps1 [worktree-name]
param([string]$Name = "row28-next")
# The new chat must not inherit CLAUDE_CODE_CHILD_SESSION (set when this script ran inside a Claude session): it turns transcript saving off (11-04).
$inner = 'Remove-Item Env:CLAUDE_CODE_CHILD_SESSION -ErrorAction SilentlyContinue; $p = Get-Content -Raw -LiteralPath tools\next_chat_prompt.txt; claude --model opus --effort high --permission-mode auto -w ' + $Name + ' $p'
Start-Process pwsh -WorkingDirectory "C:\dev\game" -ArgumentList @("-NoExit", "-Command", $inner)
