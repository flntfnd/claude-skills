# COLOR.md
Base color library for the claude-skills system.
Sourced from the Swiss International Style / International Typographic Style (1950s–1970s) and the Bauhaus primary palette (1919–1933). These are the design movements that shaped modern graphic design -- their color choices were not arbitrary but deliberate statements about what color could do in service of communication.

**This file is a foundation, not a prescription.** It provides named, curated primitives to pull from rather than inventing hex values from nothing. TASTE.md (when built) overrides anything here with personal preference. STYLES.md token modifications take precedence over this library for active projects. This library fills gaps where no preference has been specified yet.

---

# How to Use This File

Reference these colors by name when specifying primitive values in design systems:

```
color/primitive/swiss-red  → #D52B1E
color/primitive/swiss-blue → #1B4499
color/primitive/paper      → #F5F3EE
```

Do not hardcode these hex values directly into components. Always go through semantic tokens:

```
color/semantic/accent/primary → color/primitive/swiss-red
```

When TASTE.md exists and specifies a preference, use that value. When STYLES.md token modifications specify a value, use that. This library is the fallback.

---

# Swiss International Style Colors

Derived from the poster work of Josef Müller-Brockmann, Armin Hofmann, Theo Ballmer, Max Bill, and others working in the International Typographic Style from the 1950s through the 1970s. These colors were used in deliberate, limited combinations -- rarely more than two or three per composition. Fabian Burghardt's Swiss Style Color Picker (fabianburghardt.de/swisscolors) was built to capture these specific combinations.

The Swiss style used color functionally: one bold color as an accent against black and white, or two carefully chosen primaries in contrast. The colors are saturated but not garish -- they read as strong and precise, not loud.

## Reds

```
swiss-red              #D52B1E    Signal red. The Swiss flag red. Used in the most iconic posters.
swiss-red-warm         #E63229    Warmer, more orange-leaning variant. Müller-Brockmann road safety series.
swiss-red-deep         #B31B1B    Deeper crimson. Shadows, backgrounds when red is the primary hue.
swiss-red-dark         #8C1414    Dark red. Near-black use cases within a red composition.
swiss-vermillion       #E8401A    Orange-red. Appears in warmer poster compositions.
```

## Blues

```
swiss-blue             #1B4499    Cobalt blue. The classic Swiss poster blue.
swiss-blue-bright      #1A5CB5    Brighter, more electric variant. Contrast against warm yellows.
swiss-blue-deep        #0F2E6E    Deep navy-cobalt. Background use in blue-dominant compositions.
swiss-cyan             #0097A7    Cyan-teal. Appears in later Swiss style work, especially print.
swiss-cyan-bright      #00B4C8    Bright cyan. Accent use only.
```

## Yellows and Golds

```
swiss-yellow           #F5C900    Warm primary yellow. The standard Swiss poster yellow.
swiss-yellow-bright    #FCE000    Brighter, purer yellow. Closer to pure primary.
swiss-yellow-warm      #F0B800    Amber-warm yellow. Pairs with deep blue or black backgrounds.
swiss-gold             #C8960A    Deep gold. Tertiary use, printed-ink feel.
swiss-amber            #D4860A    Amber. Appears in earth-toned compositions.
```

## Greens

```
swiss-green            #1B6B3A    Forest green. Less common but appears in nature/environment posters.
swiss-green-bright     #2D8A4A    Brighter green. Spring/seasonal poster work.
swiss-teal             #0B7A6E    Blue-green teal. Mid-century crossover with cyan palette.
```

## Oranges

```
swiss-orange           #E05C1A    Warm orange. Appears in consumer/lifestyle poster work.
swiss-orange-deep      #C44810    Deep burnt orange. Background-weight orange.
```

## Neutrals and Achromatics

The backbone of Swiss design. Most compositions are primarily these with color used as accent.

```
swiss-black            #0A0A0A    Near-black. More nuanced than pure #000000 in print.
swiss-ink              #1A1A1A    Standard ink black. Primary text color.
swiss-charcoal         #2E2E2E    Charcoal. Dark backgrounds that aren't fully black.
swiss-dark-gray        #4A4A4A    Dark gray. Secondary text, supporting elements.
swiss-mid-gray         #787878    Mid gray. Dividers, secondary backgrounds.
swiss-light-gray       #B4B4B4    Light gray. Subtle backgrounds, disabled states.
swiss-pale-gray        #DCDCDC    Pale gray. Near-white backgrounds with warmth.
swiss-off-white        #F0EDE8    Off-white with slight warm tone. Paper-feel backgrounds.
swiss-paper            #F5F3EE    Warm paper. The standard Swiss background, not pure white.
swiss-white            #FAFAF8    Near-white. Slightly warm, avoids sterility of pure #FFFFFF.
swiss-pure-white       #FFFFFF    Pure white. For cases where maximum contrast is required.
```

---

# Bauhaus Primary Palette

From Johannes Itten's color theory, taught at the Bauhaus 1919–1933. These colors represent the purest articulation of primary triad thinking in 20th-century design. Influenced Swiss Style directly -- many Swiss designers studied in the Bauhaus tradition.

Itten's system: three primaries at maximum saturation, always used in relationship to each other and to the neutrals black and white. Never diluted or muddied by mixing.

```
bauhaus-red            #C8302A    Itten primary red. Neither blue-shifted nor orange-shifted.
bauhaus-yellow         #E8C018    Itten primary yellow. Warm gold-yellow, not pure lemon.
bauhaus-blue           #1E3878    Itten primary blue. Deep cobalt, not navy and not sky.
bauhaus-black          #000000    Pure black. Itten used it as a structural color, not just text.
bauhaus-white          #FFFFFF    Pure white. The ground for all other colors.
bauhaus-gray           #808080    Neutral mid-gray. Itten's intermediate between black and white.
```

Secondary palette (Itten's mixed secondaries):

```
bauhaus-orange         #D4600A    Red + Yellow. Warm, saturated.
bauhaus-green          #2A7A3A    Yellow + Blue. Forest, not lime.
bauhaus-violet         #5C2080    Red + Blue. Deep purple-violet.
```

---

# Mid-Century Modernist Palette

Colors characteristic of the broader 1950s–1970s modernist graphic design era, encompassing Swiss Style, Bauhaus legacy, and related movements (Dutch Total Design, Italian rational design). These appear frequently in the work that defined what "good design" looked like across that period.

```
modernist-red          #E0272A    The standard mid-century poster red.
modernist-blue         #1C5CB2    The standard mid-century poster blue.
modernist-yellow       #F2C200    The standard mid-century poster yellow.
modernist-green        #1E6E44    Deep functional green.
modernist-orange       #D95B1A    The characteristic mid-century orange-red.
modernist-teal         #00717A    Characteristic 1960s teal.
modernist-brown        #6E3A1C    Warm functional brown. Appears in earth-toned work.
modernist-cream        #F2EDE0    Warm cream. Slightly more yellow than swiss-paper.
```

---

# Contemporary Swiss-Influenced Palette

Colors used by designers working in the Swiss/modernist tradition today. More refined and screen-optimized than the historical originals, but maintaining the same principles: primary relationships, functional color, deliberate restraint.

## Warm Neutrals (Neo-Minimalism adjacent)

```
warm-100               #FAFAF7    Warm near-white.
warm-200               #F5F3EE    Standard warm background.
warm-300               #EDE9E2    Warm light.
warm-400               #E0DAD1    Warm mid-light.
warm-500               #C4BCB0    Warm mid.
warm-600               #9A9086    Warm mid-dark.
warm-700               #6E655A    Warm dark.
warm-800               #433B31    Warm darker.
warm-900               #2A2420    Near-black warm.
warm-950               #1A1614    Very near-black warm.
```

## Cool Neutrals (Editorial, Futuristic adjacent)

```
cool-100               #F8F9FA    Cool near-white.
cool-200               #F0F1F3    Cool light background.
cool-300               #E2E4E8    Cool light.
cool-400               #C8CACE    Cool mid-light.
cool-500               #9EA2A8    Cool mid.
cool-600               #74787F    Cool mid-dark.
cool-700               #4E5258    Cool dark.
cool-800               #2E3036    Cool darker.
cool-900               #1A1C20    Near-black cool.
cool-950               #0E1014    Very near-black cool.
```

## Accent Primaries (Screen-optimized)

These are the historical Swiss colors adjusted for modern display (wider gamut, higher brightness, WCAG compliance awareness):

```
accent-red             #D52B1E    Swiss signal red. Original value works on screen.
accent-red-light       #F04035    Lighter variant for dark backgrounds.
accent-blue            #1B4499    Swiss cobalt blue. Original value works on screen.
accent-blue-light      #2A5FCC    Brighter for dark backgrounds.
accent-yellow          #F5C900    Swiss yellow. Full saturation, warm.
accent-yellow-light    #FFDA00    Brighter for impact.
accent-green           #1B6B3A    Swiss forest green.
accent-green-light     #26924F    Lighter variant.
accent-orange          #E05C1A    Swiss orange.
accent-orange-light    #F07830    Lighter variant.
accent-cyan            #0097A7    Swiss cyan.
accent-cyan-light      #00B8CC    Brighter variant.
```

---

# Functional Color Roles

How to use this library in a design system. These map the named primitives to their semantic roles.

## Default semantic mappings (no specific style active)

```
surface/background     → warm-200  (#F5F3EE)
surface/elevated       → warm-100  (#FAFAF7)
surface/sunken         → warm-300  (#EDE9E2)

text/primary           → swiss-ink    (#1A1A1A)
text/secondary         → warm-700     (#6E655A)
text/disabled          → warm-500     (#C4BCB0)
text/inverse           → swiss-white  (#FAFAF8)

border/default         → warm-400  (#E0DAD1)
border/strong          → swiss-ink (#1A1A1A)
border/subtle          → warm-300  (#EDE9E2)

interactive/primary    → swiss-red  (#D52B1E)  — or swap for swiss-blue per brand
interactive/hover      → swiss-red-warm (#E63229)
interactive/pressed    → swiss-red-deep (#B31B1B)
interactive/disabled   → warm-500 (#C4BCB0)

feedback/error         → swiss-red       (#D52B1E)
feedback/warning       → swiss-yellow    (#F5C900)
feedback/success       → swiss-green     (#1B6B3A)
feedback/info          → swiss-blue      (#1B4499)
```

## Dark mode semantic mappings (no specific style active)

```
surface/background     → cool-900  (#1A1C20)
surface/elevated       → cool-800  (#2E3036)
surface/sunken         → warm-950  (#1A1614)

text/primary           → cool-100  (#F8F9FA)
text/secondary         → cool-500  (#9EA2A8)
text/disabled          → cool-600  (#74787F)
text/inverse           → swiss-ink (#1A1A1A)

border/default         → cool-700  (#4E5258)
border/strong          → cool-300  (#E2E4E8)
border/subtle          → cool-800  (#2E3036)

interactive/primary    → accent-red-light  (#F04035)
interactive/hover      → accent-red        (#D52B1E)
interactive/pressed    → swiss-red-warm    (#E63229)
```

---

# Color Pairing Logic

The Swiss International Style used color in systematic relationships, not arbitrary combinations. These pairings are historically verified -- they come from actual poster work.

## Primary pairings (two-color compositions)

```
Red + Black            Classic. Müller-Brockmann road safety posters. Maximum contrast.
Red + White            Swiss flag composition. Clean, forceful.
Blue + White           Maritime, institutional. Hofmann school.
Blue + Yellow          Maximum chromatic contrast. Use sparingly. Bauhaus triad.
Black + Yellow         Warning/signal. Extremely high contrast. Use for critical states.
Black + White          The Swiss Style baseline. Typography first.
Red + Yellow           Energetic. Less common in Swiss design than Bauhaus.
```

## Restricted combinations (Swiss discipline)

The Swiss Style used maximum two or three colors per composition. This rule applies to UI as well:

- One primary brand color (red, blue, or yellow)
- Black and white as the structure
- Optional: one secondary neutral (warm gray or cool gray)

Using all five accent colors simultaneously breaks the style's logic. If everything is emphasized, nothing is.

## Contrast reference (WCAG compliance)

```
swiss-ink (#1A1A1A) on swiss-paper (#F5F3EE)    → contrast ratio ~16:1  ✓ AAA
swiss-ink on warm-300 (#EDE9E2)                  → contrast ratio ~11:1  ✓ AAA
swiss-red (#D52B1E) on swiss-white (#FAFAF8)     → contrast ratio ~5.2:1 ✓ AA
swiss-red on swiss-black (#0A0A0A)               → contrast ratio ~4.8:1 ✓ AA
swiss-yellow (#F5C900) on swiss-ink (#1A1A1A)    → contrast ratio ~9.8:1 ✓ AAA
swiss-blue (#1B4499) on swiss-white              → contrast ratio ~8.3:1 ✓ AAA
swiss-blue on swiss-yellow (#F5C900)             → contrast ratio ~4.6:1 ✓ AA

swiss-yellow on swiss-white (#FAFAF8)            → contrast ratio ~1.4:1 ✗ FAIL
swiss-yellow on cool-200 (#F0F1F3)               → contrast ratio ~1.3:1 ✗ FAIL
```

Yellow fails on white or light backgrounds. Always pair it with dark backgrounds for text use.

---

# Source Notes

**Swiss International Style colors** are derived from primary source poster analysis: Müller-Brockmann's Musica Viva and road safety series, Hofmann's Basel Theater posters, Ballmer's Norm poster (1928), and related works in MoMA, Museum of Design Zurich, and the International Poster collection. Fabian Burghardt's Swiss Style Color Picker (fabianburghardt.de/swisscolors, 2015) was built to systematize these combinations -- the colors here align with those documented in his tool and the underlying poster archive.

**Bauhaus primary palette** values sourced from Hue Atlas (hueatlas.com) analysis of Itten's *The Art of Color* (1961) and documented archival originals. The specific hex `#C8302A / #E8C018 / #1E3878` represents the modal range across multiple archival sources accounting for known gamut differences between lithographic inks and RGB display.

**TASTE.md override:** When the taste extraction sessions are complete, preferred color values from actual reference sites will be added to TASTE.md and will take precedence over this library. This file provides a principled starting point; TASTE.md provides the personal filter.
