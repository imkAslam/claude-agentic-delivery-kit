# Illustrations and animated imagery: landing page, auth screens, empty states

The landing-page hero, the auth brand panel, onboarding and the empty states each carry an illustration that is **about this product**, animated with care.
- **Default:** drawn SVG built from the tokens. It's free, sharp at any size, small, and covers light and dark from one file.
- **Generated images:** only when the client approves them (§4).
- **Moving parts:** follow MOTION_AND_3D.md (coding-foundations).

## 1. What each image shows
Write one line per image in `DESIGN.md › Brand §8` (Imagery):
- **Where:** the landing hero, the auth panel, an empty state or onboarding.
- **Subject:** taken from the PRD, such as the primary persona doing the core job, the product's main object, or the outcome they get.
- **Message:** the one promise from Brand §1.
- **Motion:** what moves, and why.

Examples:
- A clinic scheduler: calendar slots fill in and a check mark appears.
- A budgeting tool: a ledger line balances and turns calm.
- A field-service app: a route draws itself to the next job.

Rules:
- Never generic filler (abstract blobs, stock people at laptops). The one exception: in a Minimalism direction, the "illustration" may be the brand's own shapes.
- People are drawn in a neutral, inclusive style.
- No real person, trademarked product or competitor's UI.

## 2. Pick the lightest format that tells the story
| Need | Format | Budget (compressed) | Notes |
|---|---|---|---|
| Hero or auth illustration with gentle motion | Inline SVG + CSS keyframes (`transform`, `opacity`, `stroke-dashoffset`) | ≤ 60 KB | **The default.** Colours are CSS variables from the tokens, so one file covers light and dark |
| A character or a multi-step story | Lottie (dotLottie `.lottie`), light player, loaded lazily | ≤ 150 KB, plus the player only on that page | Colours themed by slot; the static SVG first frame is the fallback |
| A product demo | Video loop: WebM (AV1 or VP9) + MP4 (H.264), `muted playsinline loop`, with a poster | ≤ 1.5 MB, ≤ 10 s | Paused off-screen; the poster is what loads first |
| Photographic or painted key art | AVIF + WebP with a responsive `srcset` | ≤ 200 KB at 1440 px | Generated only on approval (§4) |
| A 3D scene | Three.js / React Three Fiber | MOTION_AND_3D.md §4 | Only when the direction is Spatial or the PRD states the benefit |

No GIFs: they're heavy and their colours can't be themed. Use SVG or video instead.

## 3. Motion in imagery
- **Ambient, not busy.** One or two moving parts, slow loops (4–12 s, ease-in-out from the tokens) and small movements. The subject reads at every frame.
- **After the page is ready.** Motion starts once the page can be used, so it never delays LCP; the first frame is the static image. Loops pause when off-screen (IntersectionObserver) or when the tab is hidden.
- **Auth screens are calmer than the landing page.** The brand panel slows or stops when the user focuses a field. The mobile header doesn't move, and the motion never competes with the form.
- **Reduced motion.** Under `prefers-reduced-motion: reduce`, the static final frame shows and nothing moves; the image still makes sense without motion.
- **Accessibility.**
  - A decorative image has `aria-hidden="true"` or empty alt text.
  - An image that informs has a text alternative.
  - Nothing flashes more than three times a second.

## 4. Generated images (only on the client's approval)
- **When to offer them.** Only when `SYSTEM-PROFILE.md` lists an image or video generation tool (an MCP server or a skill). The orchestrator then asks the client at G1 as one business question: "Generated images for the landing page and sign-in (the tool, an estimated cost, the licence terms), or drawn illustrations (free)?" Recommend drawn, unless the chosen direction needs photographic art. No tool, or no approval, means drawn.
- **When approved:**
  - Build each prompt from the brand: the palette by name and hex, the style, the subject from §1. No text in the image, no real people, no logos.
  - Make 2–3 candidates per slot; the client picks with the G2 mockups.
  - Record the tool, prompt, date and licence in `DESIGN.md › Brand §8`.
  - Ship the file optimised (AVIF/WebP) in `brand/assets/illustrations/`.
- **Never:** a generated image presented as a real customer, a real photo or a real screenshot. Never generate trademarks or competitors' products.

## 5. Files and build
- **Sources:** `docs/delivery/brand/assets/illustrations/<slot>.svg` (plus a `.lottie`, a poster or approved rasters). The animation's CSS lives in the SVG's `<style>`, including the reduced-motion block. Mockups show the illustrations; boards render the first and the last frame.
- **Build:** the frontend's design-foundation ticket turns each one into a component (for example `HeroIllustration`) that reads the token CSS variables and lazy-loads any Lottie, video or 3D part. The landing and auth tickets use them.
- **Check:** `bash .claude/skills/build-design-system/scripts/check-assets.sh` checks sizes, SVG hygiene, the reduced-motion block in animated SVGs, and no GIFs.

## 6. Review (design-reviewer at G2; uiux-agent at milestone design QA)
Each of these fails as P2:
- an image that isn't about the product;
- motion with no reduced-motion state;
- a format over its budget;
- motion on an auth screen that competes with the form;
- a generated image with no recorded approval;
- a failed `check-assets.sh`.
