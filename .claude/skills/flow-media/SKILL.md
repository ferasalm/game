---
name: flow-media
description: Make images and video in Google Flow (Nano Banana images, Omni video) through Claude in Chrome, save them to inbox/ then assets/ with a manifest entry. Use before any picture, plate, portrait, title loop or VFX plate is generated or downloaded.
paths:
  - "assets/**"
  - "tools/art/**"
---
# Flow media (Claude in Chrome only)
Free first (D21): Flow before any paid image API. Paid image APIs <= $1, only with Feras's OK.

## Route (proven 2026-10-26; transcript f13b2ff6)
- **Claude in Chrome only** (his login). The built-in pane cannot download or reach localhost; a localhost receiver.py
  failed (dead end, do not retry).
- Load all Chrome tools in ONE ToolSearch call (chrome-browser skill), then work in a NEW tab at labs.google/fx/tools/flow.
- Ratios allowed: 1:1, 16:9, 9:16, 4:3, 3:4 (2:3 is refused). Images = Nano Banana (the Flow agent picks it); video = Omni.

## Upload a reference image
1. Click "Add media" (opens the menu), which creates an `input[type=file]`.
2. `file_upload` the local file into that input.
3. If the grid does not take it, dispatch a synthetic drop with javascript_tool:
```js
const f=[...document.querySelectorAll('input[type=file]')].map(x=>x.files&&x.files[0]).find(Boolean); window.__ngfile=f;
const el=document.elementFromPoint(620,330); const dt=new DataTransfer(); dt.items.add(f);
for (const ty of ['dragenter','dragover','drop']) el.dispatchEvent(new DragEvent(ty,{bubbles:true,cancelable:true,dataTransfer:dt,clientX:620,clientY:330}));
```
(A first try dropped on the drop zone's parent; the fixed-point drop is the retry that worked.)

## Generate, then download
4. Click the prompt box, type the request (the Flow agent edits the reference), send. Answer its ratio question.
5. Open the result in detail view (click the thumbnail), then run:
```js
window.ngDl2K = async () => { await new Promise(r=>setTimeout(r,1500)); const btn=[...document.querySelectorAll('button')].find(b=>(b.getAttribute('aria-label')||'').includes('Download media')); btn.click(); await new Promise(r=>setTimeout(r,800)); const it=[...document.querySelectorAll('[role=menuitem]')].find(e=>e.innerText.includes('2K')); it.click(); return location.pathname; }; await window.ngDl2K()
```
That is "Download media" then the 2K item; the file lands in ~/Downloads. List result images (>= 500 px, `/asb/` URLs):
`[...document.querySelectorAll('img')].filter(i=>i.naturalWidth>=500&&i.currentSrc.includes('/asb/'))`.
6. Claude moves ~/Downloads/<file> to `inbox/` (git-ignored), converts (jpg -> png, tools/art), then to `assets/<folder>/`
   and adds an entry shaped like the items in assets/manifest.json: `id`, `path`, `source` ("flow, owner-generated"),
   `licence`, `prompt`. Never publish or buy anything.

## Flow UI as of 2026-10-27 (flow.google.com, re-verified)
- labs.google/fx/tools/flow redirects to flow.google.com; New project -> grid + agent panel on the right.
- Do NOT click Add media -> Upload: it opens a native file picker that freezes the tab. Instead create your own
  `<input type=file aria-label="ng file picker">` with javascript_tool, `find` it, `file_upload` (files must be readable by
  the session: copy to the scratchpad first), then dispatch the dragenter/dragover/drop on the grid (snippet above).
- Ingredients: the prompt's "Add ingredients" button opens the asset list; click a row, then "Add to prompt" (order = image 1, 2, ...).
  The agent can make several images in one request ("Make 3 separate images ...").
- Download: open a tile (detail view), aria-label Download -> menu "2K Upscaled"; file lands in ~/Downloads named after the
  agent's title. Edits of one image: the detail view's "What do you want to change?" box + Enter.
- Screenshots of the tab time out while Flow renders: read document.body.innerText instead.

## Status
Route verified on 2026-10-26 (Rydan A-pose, prison-roof plate). Not re-tested in P2b: mark it "verified <date>" here at
the first real use, or note what broke in lessons.md. Open: Omni video steps are not recorded yet; add them at the first
title-loop run.
