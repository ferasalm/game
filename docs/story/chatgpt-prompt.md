# Prompt for ChatGPT: turn the story into Twine passages
Paste everything below the line into ChatGPT, then paste your story after it. Save ChatGPT's answer as a
plain text file `inbox/story_chatgpt.twee` and tell Claude "merge the ChatGPT story". Passages with a name that
already exists replace that passage's text; new names are added below the map.

---

I am writing the story of a video game and organising it in Twine. Turn the story I paste below into
Twee 3 format so I can import it. Rules:

1. Answer with one code block of Twee 3 and nothing else. No StoryTitle or StoryData passages.
2. One passage per scene, story beat, character, place or open question. Keep passages short (under 150 words).
3. Each passage starts with a header line: `:: Passage name [tags]`. Names are unique and plain: no
   brackets, braces or backslashes. Put a blank line between passages.
4. Tags, separated by spaces:
   - one type: `scene`, `character`, `place` or `question`
   - one chapter for scenes: `ch1`, `ch2`, `ch3` ...
   - one status: `idea` (not decided) or `draft` (written). Never `locked`; only I lock things.
5. At the end of a scene, link the scene(s) that come next with `[[Exact passage name]]`, one per line.
   Characters and places link the scenes they appear in.
6. Keep my words and my ideas. Do not invent story events. Where something is missing or unclear,
   make a `question` passage that asks me about it.
7. No line may start with `::` except the header lines.
8. The hero is Rydan. Use only the names I use.

Example:

```
:: The market at night [scene ch1 draft]
Rydan crosses the market as the lights fail.

[[The chase]]

:: Why do the lights fail? [question idea]
The story does not say what cuts the power.
```

My story:
