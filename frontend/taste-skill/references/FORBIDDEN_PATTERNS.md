# Forbidden Patterns — AI Tells

Banned AI design signatures. Strictly avoid these unless explicitly requested.

## Visual & CSS
* **NO Neon/Outer Glows:** No default `box-shadow` glows. Use inner borders or subtle tinted shadows.
* **NO Pure Black:** Never use `#000000`. Use Off-Black, Zinc-950, or Charcoal.
* **NO Oversaturated Accents:** Desaturate accents to blend with neutrals.
* **NO Excessive Gradient Text:** No text-fill gradients for large headers.
* **NO Custom Mouse Cursors:** Outdated and ruins performance/accessibility.

## Typography
* **NO Inter Font:** Banned. Use `Geist`, `Outfit`, `Cabinet Grotesk`, or `Satoshi`.
* **NO Oversized H1s:** Control hierarchy with weight and color, not massive scale.
* **Serif Constraints:** Serif ONLY for creative/editorial. NEVER on dashboards.

## Layout & Spacing
* **Align & Space Perfectly:** Ensure padding/margins are mathematically precise.
* **NO 3-Column Card Layouts:** The generic "3 equal cards" feature row is banned. Use 2-column zig-zag, asymmetric grid, or horizontal scrolling.

## Content & Data (The "Jane Doe" Effect)
* **NO Generic Names:** "John Doe", "Sarah Chan" are banned. Use creative, realistic names.
* **NO Generic Avatars:** No SVG "egg" or Lucide user icons. Use photo placeholders or styled alternatives.
* **NO Fake Numbers:** No `99.99%`, `50%`. Use organic data (`47.2%`, `+1 (312) 847-1928`).
* **NO Startup Slop Names:** "Acme", "Nexus", "SmartFlow" are banned. Invent premium names.
* **NO Filler Words:** Ban "Elevate", "Seamless", "Unleash", "Next-Gen". Use concrete verbs.

## External Resources & Components
* **NO Broken Unsplash Links:** Use `https://picsum.photos/seed/{random_string}/800/600` or SVG UI Avatars.
* **shadcn/ui Customization:** Never use in default state. Customize radii, colors, shadows.
* **Production-Ready:** Code must be clean, visually striking, and meticulously refined.
