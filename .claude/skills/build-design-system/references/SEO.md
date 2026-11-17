# Public site SEO

Use when the landing page ([LANDING_PAGE.md](LANDING_PAGE.md)) or any public, indexable page is in scope. The approach is adapted from the MIT-licensed `frontend-seo` skill (stareezy-1/frontend-architecture-skill) and rewritten for this kit; no code was copied.

## 1. Principles
1. **One source of truth for identity.** Site name, base URL, description, default social image and handles live in one settings module, read from config.
2. **Absolute canonical URLs from one function.** Never join the base URL and a path by hand.
3. **One trailing-slash policy**, applied everywhere. The kit default is no trailing slash.
4. **Metadata is built per route by pure functions.** The framework only mounts the result.
5. **Sitemap, robots and feed come from the content the site renders**, never from a hand-kept list.

## 2. Settings
- Base URL, site name, description, social image path, locale and handles come from `SITE_*` environment variables, listed in `.env.example`, with safe local defaults.
- Do not hardcode a real person's contact details in templates. Put a public contact only if the PRD names it as public content.

## 3. Per-route metadata
- Each route resolves exactly one title, description and canonical URL. Open Graph and Twitter cards use the same values.
- The title template is set once at the root; a page passes only its own title.
- Every indexable page has a unique description. The landing page copy comes from the approved copy deck (DESIGN.md › UX).

## 4. Discovery files
- **Sitemap:** indexable routes and published slugs only, with absolute URLs. No draft, private or admin routes.
- **Robots:** allow public paths; disallow API, admin and build internals; point to the sitemap.
- **Feed** (only if the PRD asks for one): absolute links, escaped text, newest first.

## 5. Structured data
- Use only the schema that matches the page: `Organization` or `SoftwareApplication` on the landing page, `BreadcrumbList` on nested pages, article-type schema only for real content.
- Give each entity a stable `@id` (for example `<base>/#organization`) and reference it elsewhere instead of repeating its fields.
- Mark up only what the page shows. Do not add FAQ markup unless the questions are visible on the page.

## 6. Checks before release
- [ ] Every absolute URL comes from the canonical builder.
- [ ] One canonical per page; no duplicate or relative canonicals.
- [ ] `/sitemap.xml` and `/robots.txt` are generated and reachable.
- [ ] No private routes in the sitemap; private paths disallowed in robots.
- [ ] Open Graph and Twitter values match the page.
- [ ] Structured data passes the search engine's rich-results test.
- [ ] Lighthouse SEO and performance meet LANDING_PAGE.md (≥ 90, mobile).
- [ ] Site values come from settings; no literal site values in pages.

## 7. Framework notes
- **Next.js App Router:** `metadata` or `generateMetadata`, `app/sitemap.ts`, `app/robots.ts` (see [NEXTJS.md](../../coding-foundations/references/NEXTJS.md)).
- **Other stacks:** the same builders, mounted by the framework's head and static-file mechanisms.
