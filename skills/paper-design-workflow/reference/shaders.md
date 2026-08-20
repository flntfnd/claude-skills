# Paper Shaders & AI Image Generation

## Shaders

Paper has a native shader system at shaders.paper.design. Shaders run in Paper frames as live effects, not static images — they update in real time and export as video (MP4, WebP, AVIF).

**Shipped shaders (growing list, check shaders.paper.design for the current catalog):**
- Halftone CMYK — print-style effects with extensive color control
- Halftone Dots — vintage pop-art aesthetics
- Fluted Glass — distortion + grain
- Liquid Metal — contour detection, accepts an uploaded logo as the shape
- Mesh Gradient (animated and static), Static Radial Gradient
- Image Dithering
- Pulsing Border — useful for "thinking orb" UI
- Paper Texture — fiber and crumple control
- Swirl, Water, Heatmap
- Custom GLSL fragment shaders via the built-in editor

Paper Shaders expansion is still listed "in progress" on the roadmap as of August 2026 — expect new effects and textures on a rolling basis.

**Apply a shader:** select the frame → Effects panel → Shader → choose from the library or write custom GLSL.

**Eye dropper for shaders:** sample colors from any image or another shader's output via the Foreground colors panel. `Shift+I` adds gradient colors via eye dropper.

**Style pairings:**
- Futuristic / Sci-Fi — CRT/scanline shader, grid glow shader, Pulsing Border
- Organic / Biomorphic — noise displacement, Fluted Glass
- Editorial Print — Halftone CMYK, Halftone Dots

## AI Image Generation (in-canvas)

Model lineup rotates — Paper ships updates almost weekly. As of the April 2026 build log, the shipped set is:

- **GPT Image 2** — raster generation
- **Nano Banana 2** — raster generation (Gemini-powered)
- **Quiver Arrow 1.1** — SVG generation

Hotkeys: `Shift+Cmd+I` generates raster images, `Shift+Cmd+J` generates SVG. (Earlier builds, through ~Dec 2025, shipped with Flux 2, Nano Banana Pro, OpenAI Image Edit 1.5, and Seedream 4.5 — superseded by the above. Don't assume either list is still current; check the Effects/Generate panel in Paper Desktop for what's actually available before telling a user what models exist.)

Image edits preserve original aspect ratio when possible. Generated images get placed intelligently on the canvas. The Fill panel accepts images directly and composes them with other fills. HEIC/HEIF supported.
