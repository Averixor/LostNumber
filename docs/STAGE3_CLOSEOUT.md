# Stage 3 closeout (repo hardening)

Дата: 2026-08-04

## DoD checklist (Definition of Done)

### Repo / policy gates

- [x] PR #58 (prereq-58): reviewed and merged/closed so `main` is the Stage 3 base (verify: `docs/STAGE3_REPO_HARDENING.md`).
- [x] OWNER ruleset exists for `main` (PR-only merge, required checks `release-check` + `Godot tests (4.7.1)`).
- [x] Final Stage 3 base SHA is recorded and CI on that SHA is green (see table below).

### Stage 3 change set (PRs)

- [x] baseline-doc: `docs/STAGE3_REPO_HARDENING.md` baseline + junk rescan (PR #60).
- [x] gitignore: `.gitignore` hardening (PR #61).
- [x] sot-sync: Source of Truth sync + legacy stub + VC gate (PR #62).
- [x] owner-ruleset: `stage3-main-ruleset` ruleset created + verified (PR #63 test + PR closed) (id: owner-ruleset).
- [x] adaptive-icon: adaptive icon fg/bg assets + wired export presets + AAB verify (PR #64).
- [x] bundletool-gate: local warning / CI fail + expanded AAB universal.apk dump + pinned bundletool docs (PR #65).
- [x] legacy-matrix: KEEP/ARCHIVE/REMOVE legacy retirement matrix + safety checklist (PR #66).
- [x] deps-audit: `npm audit` summary + safe fix without --force, release-check + godot tests passed (PR #67).
- [ ] closeout execution note: actual Play Console “Closed testing” smoke is not performed from this repo environment (no Play credentials/automation).

### Closed testing candidate (AAB)

> Не оголошую “completed” без реального Play opt-in / device smoke.

- [x] CT candidate is recorded in repo: `STAGE1_RELEASE_RECORD.md` and `CLOSED_TESTING_RUNBOOK.md`.
- CT status right now: `pending`
- Release AAB source commit SHA: `a6db8b2939f1379eeca057f53ae7987d77ce954a`
- Release AAB SHA-256: `c9e315afcf27aacc19a5d69b823d8e035da8c07cca8f9bbbcedb6617e5321be6`

### Firebase deferred

- [x] Firebase is not started/added during Stage 3 (deferred to later phases).

### Hygiene (post Stage 3)

- [x] Ran `git fetch --prune`:
  - прунед local tracking refs:
    - `origin/docs/stage1-closed-testing-handoff`
    - `origin/docs/stage3-repo-hardening-baseline`

## Final required identifiers

### main SHA + last verified CI (for base SHA)

| Check                 | Result  | Run/Job                                                                         |
| --------------------- | ------- | ------------------------------------------------------------------------------- |
| `release-check`       | success | https://github.com/Averixor/LostNumber/actions/runs/30894328279/job/91943513720 |
| `Godot tests (4.7.1)` | success | https://github.com/Averixor/LostNumber/actions/runs/30894328279/job/91943513673 |

Stage 3 base SHA (`main` after #58): `f2d69ddb08413c7f0746f5aff1bfb8d2dd32614d`

## PR links (Stage 3)

- [PR #58](https://github.com/Averixor/LostNumber/pull/58)
- [PR #60](https://github.com/Averixor/LostNumber/pull/60)
- [PR #61](https://github.com/Averixor/LostNumber/pull/61)
- [PR #62](https://github.com/Averixor/LostNumber/pull/62)
- [PR #63](https://github.com/Averixor/LostNumber/pull/63)
- [PR #64](https://github.com/Averixor/LostNumber/pull/64)
- [PR #65](https://github.com/Averixor/LostNumber/pull/65)
- [PR #66](https://github.com/Averixor/LostNumber/pull/66)
- [PR #67](https://github.com/Averixor/LostNumber/pull/67)

## Owner handoff (what remains outside repo automation)

- [ ] OWNER: Play Console recon + Closed testing upload + tester opt-in smoke (see `docs/CLOSED_TESTING_RUNBOOK.md`).
- [ ] OWNER: after opt-in smoke, update repo CT status from `pending` to `completed` if tests pass.
