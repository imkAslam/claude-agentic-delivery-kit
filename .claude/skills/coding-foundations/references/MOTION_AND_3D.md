# Motion and 3D guide

Use only when the PRD or a ticket asks for 3D, a scroll-driven scene or motion beyond simple transitions. Everything here is opt-in and must stay within the performance budgets ([PERFORMANCE.md](PERFORMANCE.md)). Adapted from the Apache-2.0 `3d-web-experience` skill (vibeship-spawner-skills) and the `animejs-animation` skill, rewritten for this kit; no code was copied.

## 1. Decide first
- 3D and heavy motion cost time, bandwidth and battery. Write the user benefit in the ticket (for example, a product configurator needs a 3D view of the product). If a static image does the job, use the image.
- Motion must help the user: feedback, orientation or progress. Decoration alone is not a reason.

## 2. Choose the stack
| Need | Use |
|---|---|
| A quick embedded 3D element, built by a designer | Spline runtime |
| A React app with a custom scene | React Three Fiber with its helper library |
| A non-React page, or maximum control | Three.js directly |
| Simple UI motion (fade, slide, stagger) | CSS transitions or the framework's motion library, not a 3D engine |

Use one 3D library per project. Record a choice that departs from the default in an ADR.

## 3. Assets and budgets
- Export models as GLB. The agreed budget per scene is in the PRD; as a starting point, keep a model under about 100k triangles and 5 MB after compression.
- Textures in WebP or KTX2, at the size the screen needs.
- Compress in the build (for example with gltf-transform). Ship the compressed file, not the source file.
- Load models lazily, behind a visible progress indicator and a text alternative.

## 4. Runtime (must)
- Cap the device pixel ratio (1–1.5 on mobile). Use only the lights the look needs. Reuse geometry and materials; instance repeated objects.
- Pause rendering when the canvas is off-screen or the tab is hidden.
- Dispose geometries, materials and textures on unmount.
- Measure frame time on a mid-range phone before release and record the result in REVIEW.md.

## 5. Motion (must)
- Respect `prefers-reduced-motion`: turn off scroll-linked and looping motion, and keep state changes visible without animation.
- Animate only `transform` and `opacity`. Avoid properties that trigger layout.
- Use durations and easing from the design tokens. UI transitions run 120–250 ms (UI_QUALITY_BAR check 8).
- Motion never hides required content or blocks interaction. No scroll-jacking.

## 6. Fallbacks (must)
- Detect WebGL support. Without it, show a static image with alt text.
- Every fact the 3D view shows is also in text on the page.
- The fallback path is covered by a browser test.

## 7. Controls and input
- On touch devices, orbit and zoom controls must not capture page scrolling. Limit zoom, or enable it only inside the canvas.
- Keyboard users get the same choices through real buttons (for example, for variants and colors).

## 8. Review checklist
- [ ] The ticket states the user benefit; a static image was considered.
- [ ] Models compressed, within budget and loaded lazily with progress.
- [ ] Pixel ratio, lights, draw calls and off-screen pausing set; disposal on unmount.
- [ ] Reduced motion honored; only `transform` and `opacity` animated.
- [ ] WebGL fallback with alt text; scene facts also in text.
- [ ] Touch scrolling not captured; keyboard equivalents present.
- [ ] Frame time measured on a mid-range device.
