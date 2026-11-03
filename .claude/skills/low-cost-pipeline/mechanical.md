# Mechanical lane: DeepSeek without reasoning (Feras 11-02)
DeepSeek V4.1 Flash with reasoning off writes about 1200 tokens a second. Use it for work that needs no reasoning: renames,
moving a block, applying a list of exact replacements, regenerating a table from a source, adding a field to many files.
The head decides where and writes the instructions; the worker only does what the instructions say.

## A mechanical brief (templates/brief-mechanical.md)
- `## Edits`: a numbered list, each item `file | anchor text (exact, unique) | replacement (exact)` or `file | action`. No "improve", no "also".
- `## May edit`: exactly the files in the list. The gate BREACHes any other file.
- A Pattern file for the house style, `.claude/rules/code.md` (pasted automatically), and a locked check: a test or a grep assertion per edit (`grep -c` of the new text equals the count in the list).
- Launch: `RUN_KIND=py bash tools/nv_build.sh <task> <brief> <base> fast`. A failing check sends the fix pass to the max model (nv_build.sh fast does this).

## Test it before trusting it
1. First use of a new kind of edit: one smoke edit (two files), then diff it against the list by eye.
2. After every run: `git diff <base>..` must show only the listed changes; any other line is a defect, not a bonus. Read the diff by offset, or run the grep assertions.
3. Anything with a decision in it ("choose the best name", "handle the edge case") is not mechanical: use DeepSeek high or max.
4. Record each smoke and failure in changelog.md; if a kind of edit fails twice, it moves up to DeepSeek high.
