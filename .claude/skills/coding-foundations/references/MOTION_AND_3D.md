# Motion and 3D guide

Smooth, purposeful motion within the performance budgets ([PERFORMANCE.md](PERFORMANCE.md)). Adapted from the Apache-2.0 `3d-web-experience` skill (vibeship-spawner-skills) and the `animejs-animation` skill, rewritten for this kit; no code was copied. Animated illustrations: build-design-system → ILLUSTRATIONS_AND_ANIMATION.md.

## 1. Where motion goes
| Surface | Motion | Decided by |
|---|---|---|
| Every component | Micro-interactions: hover, press, focus, open and close, 120–250 ms (UI_QUALITY_BAR check 8) | Always |
| Landing page, auth screens, onboarding, empty states | An animated illustration about the product; section reveals on the landing page | Always, within the budgets below |
| Route and view changes | A short cross-fade or slide that shows where the user went | When it helps orientation |
| A 3D scene | Three.js or React Three Fiber | **Only** when the chosen direction is Spatial, or the PRD states the user benefit (for example a product viewer). Otherwise SVG and CSS |

Motion must help: feedback, orientation, progress or the brand's first impression. Decoration on working screens is not a reason. If a static image does the job, use the image.

## 2. Choose the technique
| Need | Use | Why |
|---|---|---|
| Component states (hover, press, open, close) | CSS transitions with the motion tokens | No JavaScript; runs on the compositor |
| Enter and exit, layout changes, gestures, drag (React) | Motion (motion.dev), with `LazyMotion` and `m` components to keep the bundle small | Interruptible springs and exit animations |
| Route and view changes | The View Transitions API, through the framework's support where it has one; an instant change where the browser lacks it | Native and cheap |
| Reveal or progress on scroll | CSS scroll-driven animations (`animation-timeline: view()`) inside `@supports`, else an IntersectionObserver that adds a class | Off the main thread where supported; no scroll handlers |
| Long sequenced timelines, SVG morphing, scroll storytelling | GSAP (free to use, plugins included; check the licence when adding it) | Precise timelines and ScrollTrigger |
| Illustrations | SVG + CSS keyframes, or Lottie (ILLUSTRATIONS_AND_ANIMATION.md) | Small and themeable |
| 3D | Three.js, or React Three Fiber in a React app; Spline runtime only for a designer-built embed | §4 |
| React Native | Reanimated (runs on the UI thread) and the platform's transitions | No JS-thread jank |

Use CSS plus **at most one** motion library and **one** 3D library per project; a second one needs an ADR.

## 3. Smoothness (must)
- **Compositor-only properties.** Animate `transform` and `opacity`; use `filter` and `clip-path` sparingly. Never animate `width`, `height`, `top`, `left` or `margin`, and never read layout inside an animation loop.
- **Promote layers briefly.** Set `will-change` only while an animation runs, and remove it after. Keep promoted layers to a few.
- **Timing from the tokens:**
  - durations: `motion.duration.fast` (120 ms), `base` (200 ms) and `slow` (320 ms) for UI; 4–12 s for ambient loops;
  - easing: `motion.easing.standard` for state changes, `enter` and `exit` for things that appear or leave;
  - springs for direct manipulation (drag, toggles, sheets).
- **Interruptible.** A new interaction reverses or redirects the running animation instead of queueing behind it.
- **Restrained.** Stagger at most 5–8 items, 30–50 ms apart; long lists don't stagger. One focal movement per view.
- **Never in the way.** Motion never hides required content, blocks input or hijacks scrolling. Content is usable before any entrance animation finishes. Interaction to Next Paint (INP) stays ≤ 200 ms.
- **Reduced motion.** Under `prefers-reduced-motion: reduce`, scroll-linked, looping and parallax motion stops; state changes are still visible (an instant change or a fade ≤ 120 ms).
- **Measured.** With a 4× CPU slowdown in the browser's performance panel, no frame during the animation exceeds 16 ms (any long frame is a finding). Results go in REVIEW.md › Performance.

## 4. Three.js, optimized (when 3D is in scope)
- **Load late:**
  - Import the scene dynamically, only on the page that needs it (`import()`, or `next/dynamic` with `ssr: false`), after the LCP.
  - Show a poster image of the same size in the scene's place, so nothing shifts.
  - Use named imports from `three` and addons from `three/addons/…`.
  - Keep the route's extra JavaScript ≤ 250 kB compressed.
- **Assets:**
  - GLB with Draco or Meshopt geometry compression and KTX2 (Basis) textures, produced by `gltf-transform optimize` in the build. Ship the compressed file, never the source.
  - Textures at the size the screen needs; levels of detail for large models.
  - Budget: about 100k triangles and 5 MB per scene, unless the PRD sets another.
- **Renderer:**
  - `setPixelRatio(Math.min(devicePixelRatio, 1.5))`, or 1 on low-end and mobile devices.
  - Antialiasing only at pixel ratio 1.
  - Colour management and tone mapping set once.
- **Frame loop:**
  - Render on demand when nothing moves (React Three Fiber `frameloop="demand"` + `invalidate()`).
  - Pause when the canvas is off-screen or the tab is hidden; clamp the frame delta.
  - Lower the pixel ratio when frames run slow (an adaptive-DPR or performance-monitor helper).
- **Draw calls:**
  - Merge static meshes, use `InstancedMesh` for repeats, and share materials.
  - Use few lights: bake lighting or use an environment map. Shadows off unless needed (at most one shadow-casting light, a small shadow map).
  - At most one post-processing pass, none on mobile.
- **Per frame:** no allocations (reuse vectors and matrices) and no React state updates inside `useFrame`: mutate refs.
- **Clean up:** dispose geometries, materials, textures and render targets on unmount, then the renderer.
- **Fallbacks:**
  - Detect WebGL. Without it, show the poster image with alt text.
  - Every fact the scene shows is also in text on the page.
  - A browser test covers the fallback path.
- **Input:**
  - Orbit and zoom never capture page scrolling on touch screens: limit zoom, or enable it only inside the canvas.
  - Keyboard users get the same choices as real buttons (variants, colours).
- **Budget:** frame time ≤ 16 ms on a mid-range phone, measured before release and recorded in REVIEW.md.

## 5. Review checklist
- [ ] Each animation has a purpose (§1). 3D appears only where the direction or the PRD calls for it, and a static image was considered.
- [ ] The technique matches §2; CSS plus at most one motion library and one 3D library.
- [ ] Only compositor properties animate; timing comes from the motion tokens; animations are interruptible.
- [ ] Reduced motion is honoured; nothing blocks input or hijacks scrolling.
- [ ] No long frames at 4× CPU slowdown; INP ≤ 200 ms.
- [ ] 3D: loaded late behind a same-size poster; compressed assets within budget; pixel ratio capped; renders on demand and pauses off-screen; instancing and few lights; disposal on unmount; WebGL fallback; touch and keyboard handled; frame time recorded.
