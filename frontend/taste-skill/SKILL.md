---
name: taste-skill
description: "Senior UI/UX engineering skill that overrides default LLM design biases. Use when building premium frontend interfaces with React/Next.js, enforcing metric-based layout rules, strict component architecture, CSS hardware acceleration, anti-slop design patterns, and balanced design engineering with configurable variance dials."
allowed-tools: Bash Read Write
metadata:
  author: roundtable
  version: "1.0"
  tier: frontend
---

# High-Agency Frontend Skill

Override default LLM design biases to produce premium, non-generic UI.

## When to Use

- Building new React/Next.js interfaces that need premium aesthetics
- Redesigning existing UIs to eliminate generic AI design patterns
- Creating dashboards, landing pages, or SaaS feature sections
- Any frontend work where default LLM output feels bland or templated

## Workflow

1. Check `package.json` for installed dependencies and framework version
2. Set baseline configuration dials (or use defaults: DESIGN_VARIANCE=8, MOTION_INTENSITY=6, VISUAL_DENSITY=4)
3. Apply architecture conventions from Section 2 (RSC safety, Tailwind version lock, anti-emoji policy)
4. Build layout per variance dial using [references/DIAL_DEFINITIONS.md](references/DIAL_DEFINITIONS.md)
5. Apply design engineering directives (bias corrections) from [references/DESIGN_RULES.md](references/DESIGN_RULES.md)
6. Add motion per intensity dial using [references/CREATIVE_ARSENAL.md](references/CREATIVE_ARSENAL.md)
7. Run pre-flight check before outputting

## Active Baseline Configuration

* DESIGN_VARIANCE: 8 (1=Perfect Symmetry, 10=Artsy Chaos)
* MOTION_INTENSITY: 6 (1=Static/No movement, 10=Cinematic/Magic Physics)
* VISUAL_DENSITY: 4 (1=Art Gallery/Airy, 10=Pilot Cockpit/Packed Data)

Adapt these values dynamically based on what the user explicitly requests. Use as global variables to drive logic in referenced files.

## Architecture & Conventions

* **DEPENDENCY VERIFICATION [MANDATORY]:** Before importing ANY 3rd party library, check `package.json`. If missing, output the install command first.
* **Framework:** React or Next.js. Default to Server Components (RSC).
  * Global state works ONLY in Client Components. Wrap providers in `"use client"`.
  * Interactive components (motion, hover) MUST be isolated leaf `'use client'` components.
* **State:** `useState`/`useReducer` for isolated UI. Global state only for deep prop-drilling avoidance.
* **Styling:** Tailwind CSS (v3/v4). Check `package.json` for version — do not use v4 syntax in v3 projects. For v4, use `@tailwindcss/postcss` or Vite plugin, NOT `tailwindcss` plugin in postcss.
* **ANTI-EMOJI POLICY [CRITICAL]:** NEVER use emojis in code/markup. Use Phosphor or Radix icons.
* **Responsiveness:** Use `min-h-[100dvh]` (never `h-screen`). Use CSS Grid (never flex percentage math). Contain layouts with `max-w-[1400px] mx-auto`.
* **Icons:** Use `@phosphor-icons/react` or `@radix-ui/react-icons`. Standardize `strokeWidth` globally.

## Design Engineering Directives (Bias Correction)

**Rule 1 — Typography:** Default display to `text-4xl md:text-6xl tracking-tighter leading-none`. Ban `Inter` for premium vibes — use `Geist`, `Outfit`, `Cabinet Grotesk`, or `Satoshi`. Ban serif on dashboards.

**Rule 2 — Color:** Max 1 accent color, saturation < 80%. Ban purple/blue AI aesthetic. Use neutral bases (Zinc/Slate) with singular accents.

**Rule 3 — Layout:** Ban centered hero sections when DESIGN_VARIANCE > 4. Force split-screen, asymmetric, or left-aligned layouts.

**Rule 4 — Cards:** For VISUAL_DENSITY > 7, ban generic card containers. Use `border-t`, `divide-y`, or negative space.

**Rule 5 — Interactive States:** Always implement loading (skeleton), empty states, error states, and tactile feedback (`scale-[0.98]` on `:active`).

**Rule 6 — Forms:** Label above input, helper text optional, error text below, `gap-2` for input blocks.

## Performance Guardrails

* Apply grain/noise filters ONLY to fixed, pointer-events-none pseudo-elements
* Animate exclusively via `transform` and `opacity` — never `top`, `left`, `width`, `height`
* Use z-indexes strictly for systemic layers (nav, modals, overlays)

## AI Tells (Forbidden Patterns)

See [references/FORBIDDEN_PATTERNS.md](references/FORBIDDEN_PATTERNS.md) for the complete list of banned AI design signatures.

Key bans: neon glows, pure black (#000), oversaturated accents, Inter font, 3-column card layouts, generic names/avatars/numbers, broken Unsplash links.

## Pre-Flight Check

Before outputting, verify:
- [ ] Mobile layout collapse guaranteed for high-variance designs
- [ ] Full-height sections use `min-h-[100dvh]`
- [ ] `useEffect` animations have cleanup functions
- [ ] Empty, loading, and error states provided
- [ ] CPU-heavy perpetual animations isolated in own Client Components
- [ ] No banned patterns from AI Tells section

## References

- [references/DIAL_DEFINITIONS.md](references/DIAL_DEFINITIONS.md) — Detailed dial level specifications
- [references/CREATIVE_ARSENAL.md](references/CREATIVE_ARSENAL.md) — High-end UI patterns and motion engine specs
- [references/DESIGN_RULES.md](references/DESIGN_RULES.md) — Anti-slop implementation details
- [references/FORBIDDEN_PATTERNS.md](references/FORBIDDEN_PATTERNS.md) — Banned AI design signatures
