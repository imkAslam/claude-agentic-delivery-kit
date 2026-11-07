# Target: Mobile releases with Expo EAS (`deploy.mobile_target = eas`)

The devops-engineer owns store and release configuration. The mobile engineer never touches signing.

1. **Files:** `eas.json` with build profiles `development`, `preview` (internal distribution / staging API), `production` (store build, production API); release channels for OTA updates; `app.config.*` reading public config only (the API base URL per profile).
2. **CI steps:**
   ```bash
   npx eas-cli build --platform all --profile preview --non-interactive          # on default branch → internal testers
   npx eas-cli build --platform all --profile production --non-interactive       # release candidate
   npx eas-cli submit --platform all --profile production --non-interactive --latest   # after G3 only
   npx eas-cli update --branch production --message "<release>"                 # OTA, JS-only changes, after G3 only
   ```
3. **Secrets:** `EXPO_TOKEN`. Store credentials (the App Store Connect API key, the Play service account) are stored in EAS credentials, not in the repo.
4. **Health:** the app's startup check against the production API health path; crash-free-session monitoring (e.g. Sentry) after release; staged/phased rollout in both stores.
5. **Rollback:** halt the phased rollout; for OTA, republish the previous update (`eas update:republish`); for native changes, ship a new build. The server API stays backward compatible with the previous app version.
6. **Bootstrap:** create the Expo project and link it; Apple Developer and Google Play accounts; the app records in both stores; credentials configured in EAS; internal testing tracks/TestFlight groups; the `EXPO_TOKEN` CI secret.
