# Landing page (opt-in: PRD feature `F-LANDING`)

A public page that explains the product, who it is for, what it does and how to start. It exists **only when the client asked for it**: at intake (READINESS_RUBRIC question 11) or at G1, recorded as feature `F-LANDING` in the PRD. No `F-LANDING`, no landing page work anywhere in the run.

## 1. Where each section comes from
The page is assembled from approved artifacts, never invented. Each section has one source:

| Section | Source | Notes |
|---|---|---|
| Hero (headline, subline, primary CTA) | BRAND-BRIEF §1 positioning and purpose; the PRD sign-up or contact journey | One promise in plain words; one primary CTA (the 10% accent color) |
| Problem → outcome | PRD §1 goals, BA personas' needs | The change the product makes, in the users' terms |
| Features | `docs/FEATURES.md` rows with status **released** (or **accepted** for the release being prepared) and `Landing: shown` | 3–6 features, benefit first; never a planned or deferred feature |
| How it works | The BA primary journey (J-1), 3–4 steps | Uses the real product screenshots once built |
| For whom | BA personas (roles, not names) | One card per primary persona |
| Trust | NFRs the client approved to state publicly (security, privacy, uptime), client-provided logos or quotes | Only claims the client approved; no invented testimonials, numbers or certifications |
| FAQ | PRD business rules and open questions the client answered | Optional |
| Final CTA + footer | The CTA again; legal links (privacy, terms, imprint), contact | Legal text is `CLIENT COPY`, never drafted by agents |

## 2. Copy
- Agents draft the headline and section copy in the brand voice (VOICE_AND_TONE.md) and mark every string `CLIENT COPY (draft)` in the UI-UX copy deck. Marketing copy is a client decision (decision policy): the client approves it at **G2** (the mockup) and, on every refresh, at the **acceptance** gate.
- Legal and compliance text (privacy, terms, consent, claims about regulations) is never drafted: it is `CLIENT COPY` with a placeholder until the client provides it.
- Claims must be true of the released product. No "AI-powered", "secure" or "compliant" wording unless an approved artifact backs it (the threat model, the security audit, a client-confirmed certification).

## 3. Content as data
The page reads its text, feature list and images from one content file in the frontend's owned paths (e.g. `<web>/content/landing.content.json`, path set in PROJECT.md). A refresh then is a small data diff reviewed like any ticket, not a redesign. Layout and components come from DESIGN-SYSTEM.md and the tokens like every other screen; the 60-30-10 split applies (COLOR_METHOD §4: a landing page may show more secondary color in its section bands, the accent stays on the CTAs).

## 4. Technical baseline (the F-LANDING acceptance criteria)
- **SEO:** a unique `<title>` and meta description; canonical URL; Open Graph and Twitter card using the brand social image (`brand/assets/og-image.html` → 1200×630 PNG); schema.org `SoftwareApplication` or `Organization` JSON-LD; `sitemap.xml` and `robots.txt`; one `h1`, logical headings.
- **Performance:** server-rendered or static; Lighthouse ≥ 90 for performance, accessibility, best practices and SEO on mobile; images sized and lazy-loaded; no blocking third-party scripts.
- **Accessibility:** WCAG 2.2 AA like every screen (contrast by `check-tokens.sh`, focus, landmarks, alt text, reduced motion).
- **Privacy:** no analytics or tracking without the consent the client's privacy policy requires; analytics vendors are a client decision (cost and DPA).
- **Separation:** the landing page never shows authenticated data and never calls private API operations; it links to sign-up or sign-in.

## 5. Design (Plan & Design)
The uiux-agent adds the landing page to UI-UX.md (inventory id `S-LANDING`), wireframes it with the other key screens, and builds mockups of every section at 1440×900 and 390×844, from tokens and specified components only. The design-reviewer checks §1–§4 (DESIGN_QA §A).

## 6. Build and refresh (plan-delivery)
- **First release:** one frontend ticket *"frontend · Landing page"* (M) in the milestone that ships the sign-up or contact journey, depending on the design-foundation ticket. Its ACs are §4 plus the section map in §1.
- **Every later release:** the **last milestone of the release** gets *"frontend · Landing page refresh for <release>"* (S), depending on every feature ticket of that release. It updates the content file from `docs/FEATURES.md` (newly accepted features with `Landing: shown`) and refreshes the screenshots. Because it lands before the `acceptance` gate, the accepted candidate and the release artifact already include it; nothing changes after acceptance.
- An approved change request that adds or removes user-visible features in a release triggers the same refresh ticket.
- The refreshed copy is listed in the acceptance package (ACCEPTANCE-REVIEW "Landing page changes") for the client to approve.
