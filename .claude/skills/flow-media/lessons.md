# flow-media lessons (seed: docs/LESSONS.md section 5; dated lines, <= 40)
- The browser pane's downloads are invisible to Claude and Flow links need the owner's cookies: Chrome extension, or Feras saves to inbox/ (2026-10-23).
- Flow from Claude: the pane cannot download or reach localhost -> Claude in Chrome; upload = own input[type=file] + file_upload + synthetic drop; download = "Download media" -> 2K -> ~/Downloads; 2:3 refused (2026-10-26).
- Pictures pasted in chat are not on disk: ask him to save them to inbox/ (2026-10-23).
- First import of three 2752x1536 webp: "WebP packing failed", textures load empty -> run --import again (2026-10-26).
- lru_cache of 1280x720 float layers hit MemoryError at ~4 GB -> cache uint8 or a few entries (2026-10-25).
- ffmpeg 9 dropped `-filter_complex_script` -> `-/filter_complex file` (2026-10-25).
