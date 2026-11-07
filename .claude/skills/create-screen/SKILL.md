---
name: create-screen
description: "Creates mobile app screens and flows adapted to the project's mobile framework (Expo/React Native, Flutter, or native), with navigation, the generated API client, offline and poor-network handling, lifecycle and permissions, platform accessibility, design tokens and test-first delivery."
when_to_use: "Use when a mobile ticket needs a new or changed screen, navigation flow, form, list, offline behavior or device-permission flow."
---

# Create screen

For the **mobile-engineer** in lane `build`. It applies only when `project.json → roles.mobile.enabled` is true.

## When to Use
- New or changed screens, tabs, stacks, modals and flows
- Lists, forms and detail views backed by contract operations
- Offline/sync, push notification handling, deep links, camera/location/file permissions
- Mobile fixes routed by triage

## Instructions

### Step 0: Detect the stack
Read `project.json`: `stack.mobile`, `stack.mobile_e2e`, `roles.mobile.paths`, `roles.mobile.commands`, `contracts.codegen_cmd`. In the owned paths, find the navigation library, state/query approach, component kit, theme/tokens file and test setup. Follow the existing conventions.

### Step 1: Resolve the inputs from artifacts
| Input | Source |
|---|---|
| Layout, states, look | Mobile mockups `docs/delivery/mockups/*.mobile.png`, `UI-UX.md`, `DESIGN-SYSTEM.md` (load **design-inspiration**) |
| Colors, type, spacing, dark mode | The theme generated from `docs/delivery/tokens.json` (build-design-system → DESIGN_TOKENS.md §8). Never raw values |
| Data and errors | The ticket's contract operations → the generated client |
| Offline needs | PRD NFRs ("works offline", "sync") and the ticket's AC |
| Permissions and deep links | `UI-UX.md` flows, ticket AC |

### Step 2: Write the tests first (tdd skill)
Component tests for each state (loading, empty, error, offline, success); interactions through accessible queries; navigation assertions; API calls via the generated mocks. Add an E2E flow (e.g. Maestro/Detox) when the ticket is a primary journey and the QA ticket doesn't already cover it.

### Step 3: Build the screen
Follow [MOBILE_TEMPLATES.md](references/MOBILE_TEMPLATES.md) for the framework and [MOBILE_PATTERNS.md](references/MOBILE_PATTERNS.md) for offline, lifecycle, permissions and deep links:
- Typed navigation params; screens registered in the existing navigator
- The generated client through the project's query layer; contract errors mapped to user messages
- Every state, including offline; safe areas; keyboard avoidance for forms
- Tokens from the theme. No raw colors or sizes that have a token

### Step 4: Accessibility (platform)
`accessibilityLabel`/`Semantics` on icons and images; `accessibilityRole`; dynamic type/text scaling without clipping; touch targets ≥ 44pt/48dp; screen-reader focus order; announce errors and loading changes; no information carried by color alone.

### Step 5: Security on the device
No secrets in the bundle or in source. Tokens go in secure storage (Keychain/Keystore via the platform's secure store); no PII in logs; certificate pinning only if the threat model asks for it.

### Step 6: Verify
Run the role's commands. Run on a simulator or emulator when the toolchain is available, and save screenshots of each state to `docs/delivery/evidence/<ticket>/`. Say so if it isn't available.

## Integration with Other Skills
- **design-inspiration:** load it before UI work
- **create-component:** the shared data, error-mapping and state rules ([DATA_AND_STATE.md](../create-component/references/DATA_AND_STATE.md))
- **ship → mobile-eas:** devops owns builds, signing and store releases. Don't touch them
- **tdd / role-boundaries / review-checklists**

## File Structure
```
.claude/skills/create-screen/
├── SKILL.md
└── references/
    ├── MOBILE_TEMPLATES.md   # Expo/React Native and Flutter screen + test skeletons
    └── MOBILE_PATTERNS.md    # offline/sync, lifecycle, permissions, deep links, push, performance
```
