# Anti-Slop Implementation (Creative Proactivity)

## Liquid Glass Refraction

When glassmorphism is needed, go beyond `backdrop-blur`. Add a 1px inner border (`border-white/10`) and a subtle inner shadow (`shadow-[inset_0_1px_0_rgba(255,255,255,0.1)]`) to simulate physical edge refraction.

## Magnetic Micro-physics (MOTION_INTENSITY > 5)

Implement buttons that pull slightly toward the mouse cursor. **CRITICAL:** NEVER use React `useState` for magnetic hover or continuous animations. Use EXCLUSIVELY Framer Motion's `useMotionValue` and `useTransform` outside the React render cycle to prevent performance collapse on mobile.

## Perpetual Micro-Interactions (MOTION_INTENSITY > 5)

Embed continuous, infinite micro-animations (Pulse, Typewriter, Float, Shimmer, Carousel) in standard components. Apply premium Spring Physics (`type: "spring", stiffness: 100, damping: 20`) to all interactive elements — no linear easing.

## Layout Transitions

Always utilize Framer Motion's `layout` and `layoutId` props for smooth re-ordering, resizing, and shared element transitions across state changes.

## Staggered Orchestration

Do not mount lists or grids instantly. Use `staggerChildren` (Framer) or CSS cascade (`animation-delay: calc(var(--index) * 100ms)`) to create sequential waterfall reveals.

**CRITICAL:** For `staggerChildren`, the Parent (`variants`) and Children MUST reside in the identical Client Component tree. If data is fetched asynchronously, pass the data as props into a centralized Parent Motion wrapper.

## The "Motion-Engine" Bento Paradigm

For modern SaaS dashboards or feature sections, use this "Bento 2.0" architecture:

### Core Design Philosophy
* Background: `#f9fafb`. Cards: pure white with 1px `border-slate-200/50`.
* Use `rounded-[2.5rem]` for major containers. Diffusion shadow: `shadow-[0_20px_40px_-15px_rgba(0,0,0,0.05)]`.
* Typography: `Geist`, `Satoshi`, or `Cabinet Grotesk`. Labels outside and below cards.

### Animation Engine (Perpetual Motion)
* Spring Physics: `type: "spring", stiffness: 100, damping: 20`
* Layout Transitions: Heavily use `layout` and `layoutId` props
* Infinite Loops: Every card must have an "Active State" that loops (Pulse, Typewriter, Float, Carousel)
* **PERFORMANCE CRITICAL:** Perpetual motion MUST be memoized (React.memo) and isolated in its own Client Component

### 5-Card Archetypes
1. **The Intelligent List:** Auto-sorting loop using `layoutId`
2. **The Command Input:** Multi-step Typewriter Effect with blinking cursor and shimmer loading
3. **The Live Status:** Breathing indicators with "Overshoot" spring notification badges
4. **The Wide Data Stream:** Infinite horizontal carousel (`x: ["0%", "-100%"]`)
5. **The Contextual UI:** Staggered highlight + float-in toolbar
