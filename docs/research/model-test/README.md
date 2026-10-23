# Free-model test (2026-10-23)
task_a.txt: three GDScript functions, scored by harness.gd.txt (copy to res://.llmtest/harness.gd, put model files in
res://.llmtest/models/*.gd, run headless with -s, then delete .llmtest/). task_b.txt: root cause of the save-picker bug
(answer: the covered picker is process-disabled, so its fade tween never runs; close() must re-enable processing).
Results: Inkling 16/16 + right cause; laguna logic 16/16 but untyped (compile fail) + wrong cause; Nemotron Ultra
8/14 + no answer; GLM-5.3-Flash and DeepSeek V4.1 Flash untested (opencode free allowance used up).
