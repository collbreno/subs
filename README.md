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
