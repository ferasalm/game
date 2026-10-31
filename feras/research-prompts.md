# Research prompts for Feras (Gemini Deep Research, Argon High)
Written 2026-10-31 at row 18 from the department research queues (docs/WORKFLOW.md, Research protocol). Paste one prompt into a new
Deep Research chat, run it, share the result as a doc or drop it in inbox/. You do not need to run them all at once: the order is the
order they help the game. Results are ideas, not facts, until a source is read; a Haiku reader digests each to <= 30 lines.

| # | For | Needed before |
|---|---|---|
| 1 | Sprite memory on phones (Art) | row 6, the Roya bake |
| 2 | First 30 seconds on a phone (Market) | row 5, your M1 playtest |
| 3 | Free image-to-3D (Art) | ~11-17, when the Rodin credits end |
| 4 | Omni references and loops (Art) | row 7, the title video |
| 5 | Comparable games and price (Market) | the Steam page |

## 1. Sprite memory on Android phones
```
I am making a 2D isometric real-time action RPG in Godot 4.7 (Mobile renderer) for PC and Android. Characters are 3D models baked to
pre-rendered full-colour sprites: 8 directions, 24-30 frames per second of animation, with a normal map for each frame so that 2D lights can
move across them. Not pixel art: soft, painterly colour with more than 256 colours on screen.

Research the real memory and compression limits for this on mid-range and low-end Android phones from 2021-2025:
1. For a character with about 10 animations in 8 directions, what do the numbers come to at frame heights of 128, 256 and 512 px? Show the arithmetic for
   uncompressed RGBA8, ETC2 and ASTC (which block sizes), with and without the normal maps.
2. How much GPU memory can a game actually use on a phone with 4 GB and 6 GB of RAM before Android kills it or it stutters? Cite measured sources.
3. How does Godot 4 handle ETC2 and ASTC import for 2D textures, atlases and texture arrays on Android? What does a CanvasTexture normal map cost? Which
   known bugs or limits apply in 4.4 or later?
4. Which image artefacts do ETC2 and ASTC add to soft painted sprites and to normal maps, and which settings reduce them?
5. How do shipped 2D games with large painted sprites keep memory down: mirrored directions, fewer directions, separate body parts,
   streaming frames in and out, lower frame rates on some animations?

Give a recommendation: sprite height, directions, frames, format and atlas layout for a scene with 1 hero and 4-6 enemies. Mark each number
as measured (with its source) or estimated. Prefer engine docs, GDC talks, vendor docs (Arm, Qualcomm) and developer post-mortems over blogs.
```

## 2. The first 30 seconds of a mobile action game
```
I am making a real-time action game in the style of Hades (move, dash with invulnerability, attack, special, cast) that must play well with touch on Android.
My first public test wants outside players to use the core action without prompting within about 30 seconds and rate fun at 4 of 5 or higher.

Research what outside playtesters and players report as friction in the first 30 seconds to 5 minutes of Hades-like and top-down action games on phones.
Look at games such as Hades (Netflix mobile), Dead Cells mobile, Archero, Diablo Immortal, Genshin Impact, Soul Knight, Wild Rift and Eternium, plus playtest write-ups,
GDC talks, store reviews and Reddit threads.
1. Which touch controls fail first: virtual stick drift, thumb covering the action, aiming, dash timing, too many buttons? Give specific evidence.
2. Which control layouts solved these, with what evidence: auto-aim strength, tap versus hold, swipe to dash, button size and position?
3. What do the best games teach in the first 30 seconds, and how (no text, a first enemy, a forced dash)?
4. What separates a game that feels good on a pad or keyboard from the same game on touch?
5. Which questions and measures work best for a small playtest of 5-10 people (what to record, what to ask after, which survey wording avoids polite answers)?

End with a checklist of 10-15 pass or fail items for a first-30-seconds test, each with the evidence behind it. Mark player opinion
apart from measured data.
```

## 3. Free image-to-3D for rigged characters
```
I make game characters as 3D models, then bake them to 2D sprites. Today I use a paid tool (Hyper3D Rodin) whose access ends in mid-November 2026. I need a free
route from one or a few concept images to a character model that can be rigged and animated.

Compare the free routes available now: TRELLIS and its successors, Hunyuan3D (latest version), TripoSR, Stable Fast 3D, InstantMesh, and any newer ones, on Hugging Face Spaces,
Google Colab free tier or local use on a PC with no strong GPU.
1. For each: can it be used free today, under what quota, and what licence applies to commercial use of its output? Quote the licence terms, and name regional limits.
2. Does it take a single image, or several views? Does it give a clean A-pose or T-pose body from a concept drawing, or must the image already be in that pose?
3. Mesh quality: polygon count, quads or triangles, topology, how well it survives a remesh to under 10,000 quads, and texture resolution.
4. Which auto-rig step works on these meshes for free (Mixamo, AccuRIG, Blender Rigify, others), and what breaks: hands, loose clothing, long robes, a dagger at the belt?
5. What does a working end-to-end route look like, step by step, with times, from people who have done it? Link real examples of humanoid characters.

Rank the top 2 routes for a one-person team with no budget. For each, give the test I should run first with one image. Separate what the
sources show from what the makers claim.
```

## 4. Google Flow Omni: references and seamless loops
```
I use Google Flow (the Omni video model and Nano Banana images) to make assets for a 2D game: a looping title-screen video and short effect plates such as hit sparks,
rain and smoke. Find out how to do this well.
1. How does Omni take reference images today: how many, what kind (first frame, last frame, style, character), and how much do they control the result?
2. How do you get a truly seamless loop? Compare first-frame-equals-last-frame, prompt wording, and fixing the seam afterwards with free tools such as ffmpeg or DaVinci Resolve.
3. Can it make effect plates on a solid black or green background that key cleanly into a game? What are the best ways to get a clean alpha afterwards?
4. What are the real limits on length, resolution, frame rate and watermark, per plan? Do any terms restrict commercial use in a game?
5. Which prompt wording keeps a fixed camera and a consistent ink-comic art style across several clips?

Give 5 tested prompt patterns with their source, and a short recipe for a 6-10 second title loop. Date every claim about plans and limits, because they change often.
```

## 5. Comparable games and price
```
I am making a premium story action RPG, 3-5 hours long, in the style of Hades but linear (no roguelite runs), set in a cyberpunk version of Old Sana'a, Yemen. PC on Steam comes first, Android
later, with a free 20-30 minute demo before launch. It is a solo-developer game.

Find 10-15 comparable games released from 2019 to 2026: short, narrative or action-focused indie games on Steam and Android, including games by developers from the Arab world or with Middle
Eastern settings. For each, a table of: price at launch, length (HowLongToBeat), review count and score on Steam, estimated sales with the method named, whether it had a demo and when, team size, and whether a mobile
version sold.
Then answer:
1. What price do similar 3-5 hour action RPGs launch at, and how do reviews mention length against price?
2. How much does a free demo help or hurt, with evidence (Steam Next Fest data, published post-mortems)?
3. How do premium games at this length do on Android, and does a paid app or a free-to-try unlock work better?
4. Do games with Arab or Yemeni settings find a wider audience, what have their developers said, and what regional pricing applies?
5. What Steam page signals predict a good launch (wishlist counts at launch, conversion rates)?

Every number must have its source and date. Mark estimates as estimates (SteamDB, Gamalytic, Boxleiter method). End with a suggested price range and the 3 games closest to mine.
```
