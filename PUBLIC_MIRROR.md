# Public mirror (Type A: history-free snapshot)

Once `reya-deployments` is private, `.github/workflows/publish-public-mirror.yml`
publishes the **allowlisted current tree** to a separate public repo on every
push to `main`, as a **single orphan commit** — no source history, no commit
messages, no author info, no branches/tags.

## Setup (one-time)

1. Create the empty public repo (default branch `main`) and set `PUBLIC_REPO` in
   the workflow to match (currently `Reya-Labs/reya-deployments-public`).
2. Create a GitHub App with **Contents: Read & write**, installed on the public
   repo only. Add `MIRROR_APP_ID` and `MIRROR_APP_PRIVATE_KEY` as Actions secrets
   in this (private) repo. (Alternative: a deploy key on the public repo.)
3. Confirm `public-mirror.allow` lists exactly what may be public.
4. Push to `main` (or run the workflow manually) to seed the mirror.

## What gets scrubbed

- **History** — the mirror is one orphan commit; nothing before it exists.
- **Commit messages** — always the generic `COMMIT_MESSAGE` (`Publish`).
- **Author/committer** — the `reya-bot` identity, never real authors.
- **Timing** (optional) — uncomment the fixed `GIT_*_DATE` env vars to strip the
  sync time too.
- **Branches / tags / PRs / issues** — a fresh public repo simply has none.
- **Files** — only paths in `public-mirror.allow`; `.github/` is excluded.

## Important consequences (read before enabling)

- **Force-push rewrites the single SHA on every run and deletes the previous
  commit.** The public SHA changes each push and old SHAs become unreachable, so
  `git pull` on the mirror breaks — consumers must re-clone. Anything pinning an
  immutable `reya-deployments` commit (e.g. Cannon/GitOps today) would break.
  Enable this only **after the zero-runtime-Git gate** (PRO-711 / PRO-693 /
  PRO-760), per PRO-696. If consumers still need pinnable refs, add a
  tag/release-per-sync variant so pins remain resolvable.
- A secret present in the **current tree** would be published; the gitleaks step
  fails the run to prevent that. Keep the allowlist tight.

## Safety guardrails in the workflow

- **Empty-tree guard** — a broken allowlist can't silently wipe the mirror to
  nothing (the job fails instead).
- **Secret-scan gate** — gitleaks scans the staged tree and fails on any finding.
- **Serialized runs** — `concurrency` prevents interleaved force-pushes.
