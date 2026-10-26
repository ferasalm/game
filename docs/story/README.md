# Story map: the repo and Twine, both ways
Rydan's story lives in `rydan.twee` (Twee 3 text, in git). `tools/twine_sync.py` copies it into the Twine
desktop library (`Documents\Twine\Stories\Rydan.html`) and back. Only Rydan is playable for now.
The source is Feras's story bible, `bible.md` (from his docx, text unchanged); the map tags its CONFIRMED points
`locked`, its proposals `draft`, its open points `question`, and collisions with docs/DECISIONS.md `check`.

- Claude edits `rydan.twee`, then `python tools/twine_sync.py push` (refused while Twine is open, or when
  Twine has edits not pulled yet).
- Feras opens Twine, moves, edits, links and tags passages; Twine saves by itself.
- `python tools/twine_sync.py pull` brings his edits back (fine while Twine is open). Then commit `rydan.twee`.
- ChatGPT output: `chatgpt-prompt.md` -> `inbox/story_chatgpt.twee` -> `twine_sync.py merge <file>` -> push.
- `twine_sync.py status` says which side changed. Tags: idea, draft, locked, check (see the "Read me" passage).
