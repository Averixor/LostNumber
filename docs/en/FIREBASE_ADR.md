---
language: en
title: Lost Number — Firebase Architecture Decision Record
version: kickoff
last_updated: 2026-08-04
status: accepted-for-kickoff
runtime: blocked-until-FIREBASE_STAGE4_GATES
---

# ADR — Firebase Cloud Save (Phase 6 / Stage 4)

## Status

**Accepted for documentation kickoff.** Runtime implementation is **blocked** until OWNER completes [`docs/FIREBASE_STAGE4_GATES.md`](../FIREBASE_STAGE4_GATES.md). Offline-first remains; Firebase stays optional.

## Context

Lost Number ships as a Godot 4.7 Android puzzle. Local saves use `SaveManager` (`user://` envelope + SHA-256 + `.bak`). **Auth B2** already enables `permissions/internet=true` and optional Google Sign-In via `LostNumberFirebase` / `AuthManager` (no Cloud Save yet). An existing Android plugin ([`LostNumberMigration`](../../godot/android/plugins/LostNumberMigration.gdap)) shows the supported pattern: Godot Android plugin → native AAR → GDScript bridge — for **legacy save import**. This ADR covers **Cloud Save / Firestore** (Stage 4B), not Auth.

## Decision

### Bridge: Godot Android Kotlin plugin (not WebView / JS / Capacitor)

| Choice                                  | Rationale                                                           |
| --------------------------------------- | ------------------------------------------------------------------- |
| **Adopt** Kotlin Android plugin + AAR   | Same ship model as Migration; native Firebase Auth/Firestore SDKs   |
| **Reject** WebView / JS SDK / Capacitor | Godot-only ship; no web runtime in product; Capacitor stack retired |

Proposed layout (runtime PRs, not this kickoff):

- `godot/android/plugins/LostNumberFirebase.gdap`
- `godot/android/plugin_src/lostnumber-firebase/` → reproducible AAR
- GDScript ↔ Android singleton ↔ Firebase Auth / Firestore

### Data flow: SaveManager-first

```text
GameState → SaveManager.save_game() → verified local write
         → only then CloudSyncManager may upload
```

- Local save remains canonical for gameplay and crash recovery.
- Cloud upload must not run before local verification succeeds.
- Cloud failure must never corrupt or block the local save.
- Boot and play work fully without account or network (no blocking auth popups).

### Firestore document path

```text
users/{uid}/save/current
```

### Envelope fields (cloud document)

| Field                        | Role                                                                          |
| ---------------------------- | ----------------------------------------------------------------------------- |
| `schemaVersion`              | Cloud envelope schema                                                         |
| `gameSaveVersion`            | Aligns with local GameState / save schema                                     |
| `revision`                   | Monotonic conflict key (preferred over timestamps)                            |
| server / client timestamps   | Audit / diagnostics only                                                      |
| `deviceId`                   | Last writer hint                                                              |
| `appVersion` / `versionCode` | Build identity                                                                |
| `payloadChecksum`            | Integrity of `payload`                                                        |
| `payload`                    | Compact GameState; **no** custom background files, tokens, or unnecessary PII |

### Conflict resolution

- Compare **`revision` + `payloadChecksum`**; present a **dialog**: keep local / use remote / cancel.
- **No field-merge** of grid or progress objects.
- Supersedes older Phase 6 sketch of “greater `updatedAt` wins” without user choice ([`docs/PHASES.md`](../PHASES.md) updated to match this ADR).

### Local-only assets

Custom backgrounds under `user://custom_backgrounds/` stay **device-local** — not uploaded to Firestore.

### Auth

- **Google Sign-In only** (no Anonymous / Email / Phone / Facebook / Apple in Stage 4 MVP).

### App Check

- Document debug provider / Play Integrity in later PRs.
- **Enforcement off** until a separate OWNER sign-off.

### Explicit non-goals (this Stage)

- Crashlytics, Analytics, Remote Config (not auto-enabled).
- Leaderboards / remote meta (**4C**, separate PR after Cloud Save sign-off).
- Mixing Firebase with visual polish or legacy deletion PRs.

## Consequences

- Privacy / Play Data safety must update in the same wave as `INTERNET=true` ([`FIREBASE_PRIVACY_DELTA.md`](../FIREBASE_PRIVACY_DELTA.md)).
- Dual Firebase projects (`lost-number-dev` / `lost-number-prod`); secrets gitignored ([`FIREBASE_OWNER_RUNBOOK.md`](../FIREBASE_OWNER_RUNBOOK.md)).
- Recommended Firestore region: **`europe-west3`** (OWNER confirms before prod project creation).

## Related

- OWNER sequence: [`docs/FIREBASE_STAGE4_SEQUENCE.md`](../FIREBASE_STAGE4_SEQUENCE.md)
- Gates: [`docs/FIREBASE_STAGE4_GATES.md`](../FIREBASE_STAGE4_GATES.md)
- Roadmap Stage 4: [`docs/ROADMAP.md`](../ROADMAP.md)
- Phases: [`docs/PHASES.md`](../PHASES.md)
- SoT: [`docs/en/SOURCE_OF_TRUTH.md`](./SOURCE_OF_TRUTH.md)
