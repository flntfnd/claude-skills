# Liquid Glass (Navigation Layer)

Covered in detail in `apple.md` / `apple-platform` (Apple platforms) elsewhere in this skill library. Summary for cross-platform reference:

Glass belongs on the navigation layer. Content sits below it. The material adapts to what's behind it. Liquid Glass is a layout decision, not a surface texture applied after the fact.

**When to use**: iOS 26+, iPadOS 26+, macOS Tahoe 26+ apps that follow Apple's HIG.

## Visual Signature

Identifiable at a glance by: navigation bars, tab bars, and toolbars that are translucent -- you can see content scrolling beneath them. The glass material bends and refracts what's behind it. Content is rich and colorful, with the navigation chrome floating above it rather than sitting on a separate opaque surface. Everything below the navigation layer fills edge-to-edge.

**Wrong if:** the navigation bar has a solid opaque background fill, content doesn't extend behind the glass layer, or glass treatment is applied to content-level elements (list rows, cards, images). Glass is navigation-layer only. On web, this style is not achievable -- use Glassmorphism (`glassmorphism.md`) instead.

**On Web**: Liquid Glass as Apple defines it (real-time lensing, specular response to device motion) is not achievable in a browser. Use the Glassmorphism / Frosted style (`glassmorphism.md`) for web surfaces that need the same depth and translucency intent. The Figma Glass effect with Refraction and Frost parameters approximates the visual for mockups, but the web implementation falls back to `backdrop-filter: blur()` with appropriate fill opacity and inner highlight stroke.

**Known usability failure modes** (documented by NN/g and others in iOS 26's release): text placed over glass controls that sits on top of other text becomes unreadable; glass navigation bars that blend into complex wallpapers become invisible; overuse of motion and physics in the glass layer creates an interface that competes with content for attention rather than supporting it. These are failure modes to avoid, not examples to follow.

## Platform Implementation

**iOS / SwiftUI**
`.glassEffect()` modifier. All native -- no custom Metal needed. Post-processing (Three.js-style techniques) would be wrong here; the system's own rendering engine handles the lensing.

Token and full component-level implementation details for native: `apple.md` / `apple-platform`.

Signature technique and why this style has no direct web equivalent: see `SKILL.md` → Style-to-Technique Mapping, item 4.
