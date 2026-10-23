# Free-model test (2026-10-23)
task_a.txt: three GDScript functions, scored by harness.gd.txt (copy to res://.llmtest/harness.gd, put model files in
res://.llmtest/models/*.gd, run headless with -s, then delete .llmtest/). task_b.txt: root cause of the save-picker bug
(answer: the covered picker is process-disabled, so its fade tween never runs; close() must re-enable processing).
Results: Inkling 16/16 + right cause; laguna logic 16/16 but untyped (compile fail) + wrong cause; Nemotron Ultra
8/14 + no answer; GLM-5.3-Flash and DeepSeek V4.1 Flash untested (opencode free allowance used up).
2026-10-23 retest: Ling 3.1 Flash (inclusionai/ling-3.1-flash, PAID, owner allowed $0.10) 16/16 typed + right cause
(close before emitting) for $0.016 both tasks; ties Inkling. Nemotron 3 Ultra :free not run: OpenRouter refused with
"free-models-per-day" (accounts under $10 of purchased credit get 50 free requests a day, shared with Inkling :free).
Run tests with stdin closed (`< /dev/null`): an open stdin made opencode wait 25 min and print nothing.
