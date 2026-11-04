# Opens a NEW Claude Code chat in its own window with the next-chat prompt (HANDOFF "Prompt for the next chat").
# Run after the previous chat merged and synced C:\dev\game. Usage: pwsh tools\next_chat.ps1 [worktree-name]
param([string]$Name = "row28-next")
$inner = '$p = Get-Content -Raw -LiteralPath tools\next_chat_prompt.txt; claude --model opusplan --effort high --permission-mode auto -w ' + $Name + ' $p'
Start-Process pwsh -WorkingDirectory "C:\dev\game" -ArgumentList @("-NoExit", "-Command", $inner)
