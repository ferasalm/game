Unverified research (D18): ideas, not facts. Read 2026-10-31.

# Lighting Pre-Rendered Sprites with Normal Maps in Godot 4

### 1. Setup Steps (Godot 4 Docs)
In Godot 4, 2D normal mapping uses `CanvasTexture`. Create a `CanvasTexture` resource, assign the albedo image to `diffuse_texture`, and the tangent-space normal map to `normal_texture`. Assign this `CanvasTexture` to `Sprite2D.texture`. Add a `PointLight2D` with an omni light texture (e.g., radial `GradientTexture2D`). Use a `CanvasModulate` node to darken global ambient light so normal highlights and shadows become visible (Source: Godot 4 Docs, "2D lights and shadows", "CanvasTexture").

### 2. Blender Baking & Axis Conventions
Bake high-to-low geometry in Blender Cycles ("Selected to Active", Bake Type: Normal, Space: Tangent). Godot 4 requires OpenGL format normals where X+ points right (Red), Y+ points up (Green), and Z+ points outward (Blue). Blender natively bakes OpenGL format (Y+ up), matching Godot 4 directly. If baking from tools using DirectX (Y- down), check "Normal Map > Flip Y" in Godot's texture Import dock (Source: Blender Manual "Render Bake", Godot 4 Docs "StandardMaterial3D/CanvasItem normal map").

### 3. Flipped Sprites & Broken Normals
Setting `Sprite2D.flip_h = true` or `scale.x = -1` horizontally flips the texture UVs but does not invert the tangent normal vector's X/Red channel. Consequently, normal angles point mathematically in the wrong direction relative to world lights, causing inverted/hollow shading on flipped sprites. Avoid runtime flipping: pre-render all 8 isometric directions or use a custom `CanvasItem` shader that flips `NORMAL.x` when mirrored (Source: Godot Engine Issue #70517).

### 4. Light Masks & Isometric Shadows (LightOccluder2D)
`LightOccluder2D` casts flat screen-space 2D shadow geometry. In isometric projection, shadows project flatly across ground planes rather than scaling up vertical wall faces. Restrict shadow projection using `occluder_light_mask` and `item_cull_mask` layers so wall occluders only block roof surface lights and do not self-shadow floor tiles (Source: Godot 4 Docs "2D lights and shadows", "LightOccluder2D").

### 5. Mobile Renderer Performance Limits
Godot 4's Mobile renderer (Vulkan Mobile) calculates 2D lights in a single forward pass. Performance bottlenecks stem from overdraw and fill-rate rather than draw-call batches. Per-object active light limits apply (`rendering/limits/opengl/max_lights_per_object`, default 8). Shadow passes from `LightOccluder2D` add separate rendering cost. Keep light textures small (power-of-two, e.g., 256x256) and cull off-screen lights (Source: Godot 4 Docs "2D lights and shadows", "ProjectSettings").

### 6. Known Bugs (4.4 and Later)
- **#70517**: Normal map lighting does not invert properly when `flip_h` or `flip_v` is set on `Sprite2D` (https://github.com/godotengine/godot/issues/70517).
- **#82334**: Non-power-of-2 `PointLight2D` textures distort or misbehave under Vulkan Forward+/Mobile (https://github.com/godotengine/godot/issues/82334).
- **#70703**: Vulkan crash when assigning `CanvasTexture` directly as light texture (https://github.com/godotengine/godot/issues/70703).
- **#81152**: Multiple 2D lights create heavy fill-rate lag on Android Vulkan mobile drivers (https://github.com/godotengine/godot/issues/81152).

## For us
1. Bake distinct 8-direction sprite frames with OpenGL (Y+ up) tangent normals; never use `flip_h` at runtime.
2. Package each frame into a `CanvasTexture` linking diffuse and normal maps for Rydan and guards.
3. Keep moving lights to 2-3 `PointLight2D` nodes using small 256x256 power-of-two textures.
4. Tint ambient darkness with a single roof-level `CanvasModulate` node to keep Mobile fill-rate low.
5. Place thin `LightOccluder2D` segments only at rooftop wall footings with isolated light masks.

## Sources
- https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html
- https://docs.godotengine.org/en/stable/classes/class_canvastexture.html
- https://docs.godotengine.org/en/stable/classes/class_pointlight2d.html
- https://docs.godotengine.org/en/stable/classes/class_lightoccluder2d.html
- https://github.com/godotengine/godot/issues/70517
- https://github.com/godotengine/godot/issues/82334
- https://github.com/godotengine/godot/issues/70703
- https://github.com/godotengine/godot/issues/81152
