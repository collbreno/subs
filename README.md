# Subs

Android application for tracking personal and shared subscriptions.

## Architecture

The project uses a lightweight hexagonal architecture:

- `lib/domain`: business entities and invariants, with no Flutter or database dependencies.
- `lib/application/ports/inbound`: use cases exposed to the UI.
- `lib/application/ports/outbound`: persistence and infrastructure contracts.
- `lib/application/services`: use-case implementations.
- `lib/adapters/inbound/flutter`: Material 3 pages and BLoCs.
- `lib/adapters/outbound`: infrastructure adapters.
- `lib/app`: composition, theming, and routing.

Navigation uses `go_router` with a stateful shell and one navigation stack per
Material navigation destination. SQLite schema version 1 lives in
`database/migrations/001_initial_schema.sql`.

The outbound SQLite adapters execute that migration unchanged and expose
reactive repository streams to the BLoCs. On first launch, the app creates the
local user (`Me`) and starter categories (`Other`, `Utilities`, and
`Entertainment`).

## First-run flows

- Create and list people.
- Create and list credit cards.
- Create boleto or credit-card subscriptions.
- Select equal-share participants for a subscription.
- List current subscriptions and the current user's calculated share.
- Expand a credit card to see its current subscriptions.

## Run

```sh
flutter run
```

## Verify

```sh
flutter analyze
flutter test
```

## Download an Android APK

The `Android APK` GitHub Actions workflow builds a signed release APK on every
push to `main`. It can also be started manually from **Actions → Android APK →
Run workflow**.

When a run finishes, open it on GitHub and download `subs-android-apk` from its
**Artifacts** section. GitHub downloads artifacts as a ZIP; extract it on the
Android device and open the APK to install it. Android may ask you to allow the
browser or file manager to install unknown apps.

The same workflow also publishes a direct APK download page at
<https://collbreno.github.io/subs/>. GitHub Pages must use **GitHub Actions** as
its source under **Settings → Pages**.

The workflow requires these repository Actions secrets:

- `ANDROID_KEYSTORE_BASE64`: base64 contents of `android/app/upload-keystore.jks`.
- `ANDROID_KEYSTORE_PASSWORD`: the `storePassword` from `android/key.properties`.
- `ANDROID_KEY_ALIAS`: the `keyAlias` from `android/key.properties`.
- `ANDROID_KEY_PASSWORD`: the `keyPassword` from `android/key.properties`.

Add them at **Settings → Secrets and variables → Actions → New repository
secret**. Keep the local keystore and `android/key.properties` backed up in a
secure location. Future APK updates must be signed with the same key.
