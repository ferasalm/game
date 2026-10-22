# Art prompts v0.3: herb seller, model pictures, hilt, item icons, sabil concept
Owner-made art (Google Flow and Gemini, $0). Character model pictures (sections 1, 2a, 2b, 2c) are for image-to-3D
(characters-3d.md section 8): painted, semi-realistic, full body, A-pose, front view, even flat light, plain mid-grey
background, 768x1376 portrait. Icons and the sabil concept keep the flat #00FF00 background.
Each prompt is one block. Save each result under the name given, in the repo's inbox/ folder (git-ignored).

## 1. Herb seller, full body (Flow, image)
```
Painted digital illustration, detailed brushwork, full-body portrait of a 40-year-old Yemeni man, a herb seller at a rooftop stall in cyberpunk Sana'a, year 2150. Forties, warm tan skin with fine lines at the eyes, short dark hair with a little grey at the temples, under a layered indigo head wrap. Practical layered clothing: an indigo wrap garment over a brick-red shirt and dark trousers, a brick-red shawl over his shoulders. A woven basket of pink- and yellow-feathered herbs hangs from his hip. He holds a small brass oil lamp in one hand. A subtle glowing cyan earpiece on one ear. Front view, camera at chest height, little perspective. A-pose: arms 30-45 degrees down from the body, not a T-pose, fingers apart, legs slightly apart, feet visible. Flat even light, no cast shadows, no rim light. Calm expression. Head to feet, 768x1376 portrait. Background: one plain mid-grey colour, no green, no gradient, no shadow on the background, no text, no frame, no logo.
```
Save as `inbox/flow_abunabil_model_front.png`.

## 2a. Zayd model picture (Flow, image)
```
Painted digital illustration, detailed brushwork, full-body model reference of Zayd al-Sana'ani, 28, a courier-fixer of the souq guild in cyberpunk night Sana'a, year 2150. Practical coat and a scarf worn close to the body. He wears his grandfather's jambiyah sheathed at the front of his belt, Yemeni style, its hilt clearly visible: old horn and silver, with a carnelian-red accent. Front view, camera at chest height, little perspective. A-pose: arms 30-45 degrees down from the body, not a T-pose, fingers apart, legs slightly apart, feet visible. Flat even light, no cast shadows, no rim light. Head to feet, 768x1376 portrait. Background: one plain mid-grey colour, no green, no gradient, no shadow on the background, no text, no frame, no logo.
```
Save as `inbox/flow_zayd_model_front.png`. Then ask for matching side and back views as separate pictures, same prompt
with "Side view" or "Back view" in place of "Front view", saved as `inbox/flow_zayd_model_side.png` and `inbox/flow_zayd_model_back.png`.

## 2b. Bilqis model picture (Flow, image; attach the Bilqis full-body picture as the reference)
```
Painted digital illustration, detailed brushwork, full-body model reference of this same character, Bilqis, as the attached picture. Keep her colours, outfit, headscarf, long coat and cyan visor exactly as in the reference. She carries no jambiyah. Front view, camera at chest height, little perspective. A-pose: arms 30-45 degrees down from the body, not a T-pose, fingers apart, legs slightly apart, feet visible. Flat even light, no cast shadows, no rim light. Head to feet, 768x1376 portrait. Background: one plain mid-grey colour, no green, no gradient, no shadow on the background, no text, no frame, no logo.
```
Save as `inbox/flow_bilqis_model_front.png`. Then side and back views the same way as 2a.

## 2c. Grandfather's jambiyah hilt (Flow, image)
```
Painted digital illustration, detailed brushwork, a Yemeni jambiyah dagger hilt and its sheath, shown alone. Old horn and silver hilt, with a carnelian-red accent on the grip and a worn, hand-polished finish. The sheath is dark leather with silver fittings. Front view and side view, both in the same picture, the hilt centred and nothing cropped. Flat even light, no cast shadows, no rim light. Background: one plain mid-grey colour, no green, no gradient, no shadow on the background, no text, no frame, no logo.
```
Save as `inbox/flow_hilt_grandfather_a.png`.

## 3. Item icons, 2x2 grid (Gemini, no attachment)
```
Painted digital illustration, detailed brushwork, a 2x2 grid of four game item icons on a flat plain bright green (#00FF00) background, each icon centred in its cell with wide empty green space around it. Top left: a sprig of herbs with pink feathery leaves tied with a thread. Top right: a sprig with yellow feathery leaves. Bottom left: a sprig with white soft feather-like leaves. Bottom right: a small clay cup of qishr (Yemeni coffee-husk drink), dark amber liquid, with rising steam. Same painted style and upper-left light as the characters: warm key light, soft shadows, clean edges. Each icon fits a square, roughly the same size. No text, no labels, no frame, no shadow on the background, no logo.
```
Save as `inbox/icons_herbs.png`.

## 4. Sabil concept (Gemini, optional, no attachment)
```
Painted digital illustration, detailed brushwork, concept art of a sabil, an old public water fountain set into a tower-house wall on a night rooftop in old Sana'a, Yemen, year 2150. A carved white gypsum arch frames a brass tap and a worn stone basin at waist height. Above it hangs a qamariya stained-glass lamp glowing in red, amber, green, blue and violet panes. White gypsum trim on mud-brick walls, a few faint cyan neon accents, a distant glow from the city. Night sky with a moon behind the rooftops. Warm light from the lamp, cool moonlight from the upper left. Eye-level, straight on, medium-wide framing, 16:9 landscape. No people, no text, no signs, no logo.
```
Save as `inbox/concept_sabil.png`.

## How to use
1. Flow and Gemini prompts above: paste, generate, download to C:\dev\game\inbox\ with the name shown.
2. Model pictures (1, 2a, 2b, 2c) go into inbox/ for the image-to-3D step (characters-3d.md section 8), not for cutting
   parts. Keep the reference picture attached for 2b.
3. Tell Claude the file names when they are ready; it will run the image-to-3D step or import them and log the source in the manifest.
