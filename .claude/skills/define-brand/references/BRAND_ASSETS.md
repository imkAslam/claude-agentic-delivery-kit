# Brand asset kit

Sources live in `docs/delivery/brand/assets/` (SVG, or HTML for composed images), with a PNG render next to each where a raster is needed. Engineers copy or generate the platform files from these sources in the design-foundation tickets of `ms-1`; the sources remain the single origin.

| Asset | Source | Exports (who wires it in) | Notes |
|---|---|---|---|
| Logo: full, mark, mono, inverse | `logo.svg`, `logo-mark.svg`, `logo-mono.svg`, `logo-inverse.svg` | SVG in the app (frontend, mobile) | Text converted to paths, `viewBox` set, no embedded raster |
| Favicon | `favicon.svg` (the mark, simplified for 16 px) | `favicon.svg`, `favicon.ico` (16/32/48), `apple-touch-icon.png` 180×180 (frontend) | Test legibility at 16 px |
| Web app manifest icons | `app-icon.svg` | 192×192, 512×512, maskable 512×512 with a safe zone (frontend) | Only if the PRD includes a PWA |
| iOS app icon | `app-icon.svg` | 1024×1024 PNG, no transparency, no rounded corners (mobile) | The platform applies the mask |
| Android adaptive icon | `app-icon-foreground.svg` + a background color | 432×432 foreground inside a 288 px safe zone; monochrome layer (mobile) | |
| Splash / launch screen | `splash.svg` | Per the mobile framework's splash config (mobile) | Background = `color.bg.default`, mark centered |
| Social preview (Open Graph) | `og-image.html` | 1200×630 PNG (frontend) | Product name + one-line value; text ≥ 48 px |
| Email header/footer | `email-header.html` | Inline-styled HTML, 600 px wide, PNG logo at 2× (backend email templates) | Works with images off (alt text, background colors) |
| Error pages | 404 / 500 mockups | Screens (frontend) | Voice: honest and helpful |
| Store listing (if mobile) | Screenshot frames | Sizes per store; the store listing text is client copy (business) | The listing itself is an account action for the client |

## Rules
- Every asset uses tokens.json colors and the BRAND-BRIEF fonts; nothing loads from the network.
- Raster exports are rendered with `bash .claude/skills/build-design-system/scripts/render-png.sh <source.html> <out.png> <WxH>` (wrap an SVG in a minimal HTML page first); report the command and its exit code. Never fabricate a file.
- Agent-made marks are proposals until the client approves the logo at G2.
