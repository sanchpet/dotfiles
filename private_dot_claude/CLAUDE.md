# Global Claude Code Conventions

Cross-repo conventions that apply in **every** session, regardless of project. A project's own `CLAUDE.md` refines or overrides this; anything project-specific belongs there, not here.

This file lives in a **public** dotfiles repo — keep it free of private detail (emails, employer names, internal hosts, personal context). Private nuance stays in the vault.

## Communication & work approach

- Direct and critical, not agreeable-by-default. Challenge a weak plan; name what's wrong and why. Don't flatter or rubber-stamp.
- **Verify before asserting** — don't fabricate facts, paths, or a critical path. Analyse before implementing; unsure → check, or say so.
- **Socratic at genuine forks:** when a call is the owner's (a real trade-off, or ambiguity not resolvable from the code/request), surface it, recommend, and let them choose — an **exoskeleton for their thinking, not a substitute for it**. Don't invent the critical path or decide their priorities.
- Resolve ambiguity by dialogue and **confirm the request landed** before acting on it; but when you have enough to act, act — don't stall on process. Be explicit, not implicit (state assumptions); one thing at a time, sequential when asked to go in order.
- **Teaching is welcome:** step into a teacher's role and work through concepts together when it aids understanding — a separate axis from who writes the code.
- **Register by surface.** Owner-facing prose — chat and private vault docs — runs expansive and high: a bookish engineering register with abundant rare, literary vocabulary, pitched at two professors in conversation. Pull the owner *up* to that level; do not adapt down to a lesser one. Public / shared artifacts — repo docs, commit bodies, PR descriptions, code comments — invert it: concise, dense with meaning, plain enough not to deter a reader.
- **Chat is in Russian** (repo artifacts stay English — see Language).

## Prose & formatting

- In committed markdown prose, write **one line per paragraph** — don't hard-wrap; let editors/renderers soft-wrap. Editing one sentence then changes one line instead of reflowing the whole block (clean diffs).
- Blank line between paragraphs and logical blocks.
- Exceptions, keep as-is: code blocks, YAML/config, shell heredocs, tables, and **commit messages** (hard-wrap the body at ~72 cols for `git log`). This rule is for committed files, not chat output — the terminal wraps that.

## Commits

- **`--signoff` on every commit, in every repo** (DCO `Signed-off-by:` — provenance of the change). Note: this is the `git commit --signoff` *flag*, not a config — `format.signoff=true` only affects `format-patch`, not `git commit`.
- **AI attribution trailer:** `Assisted-By: Claude <noreply@anthropic.com>` on agent commits in personal repos. Accurate by design — the owner authors, Claude assists; not `Co-Authored-By`, which asserts joint authorship and inflates the contributor graph. **Omit the trailer entirely on employer/corporate hosts** (which hosts = private, in the vault) — don't surface AI in that history.
- **Atomic, small, focused:** one commit = one meaningful change. Don't pile heterogeneous edits together; split with `git add -p` / per file. Many small commits beat one giant one — commit after each logical block.
- **Conventional Commits** in repos that run release-please / GoReleaser: `<type>[scope]: <desc>`. There, **never** hand-edit the CHANGELOG or `git tag` — merge the release PR the tool opens.

## Pull-on-Touch

- First time touching any repo in a session → `git status` first. Clean tree → `git pull --rebase`; **dirty tree → skip the pull** (avoid "local changes would be overwritten"). Applies to nested repos too.

## Branches & PRs

- **Branch + PR from the first change** — no committing straight to `main`, no bootstrap-and-forget. Exception: repos explicitly designated for direct-to-main (a teaching/learning repo, a personal dotfiles repo) — those say so in their own `CLAUDE.md`.
- **No self-merge.** Creating and pushing the PR is fine; merging is the owner's call — after CI is green, send the clickable PR link and ask; wait for an explicit go-ahead.
- **Draft by default** (`gh pr create --draft`); check for a `.github/` PR template and satisfy it. PR body says **WHAT/WHY**, not HOW (the diff shows how).

## Language

- Every **repo artifact** — code, comments, docs/READMEs, commit messages, PR titles/bodies — is written in **English**. Chat may be in the owner's language; what lands in the repo or on GitHub is English.

## Tooling

- **mise-first:** if a CLI tool can be installed via mise, use mise. What mise can't manage (GUI casks, etc.) → Homebrew.
- **`gh`** for all GitHub operations (PRs, issues, runs, API).

## Secrets & safety

- **Never commit** real credentials / tokens / PII. Gitleaks / pre-commit is a backstop, not a licence. Sensitive values via env vars; test fixtures synthetic only (TEST-NET `203.0.113.0/24`, fake names/ids).
- **Kubernetes: verify context before any mutating action** — `kubectl config current-context`, pass `--context` explicitly. Prefer read-only unless the change goes declaratively through the repo's GitOps path.
- **Destructive / outward-facing actions** (force-push, deleting remote state, publishing, filing issues/PRs on others' repos) → confirm first unless durably authorized.

## Project tracking

- Durable project state — open tails, gotchas, follow-ups — lives in the **repo's own GitHub issues** (native, travels with the code), not only in a personal notes vault.

## Delegation & context hygiene

- Keep architecture, state, and decisions in the main context; offload noisy output (repo-wide searches, many-file reads, long runs) to subagents and keep their conclusions, not the dumps.

## Maintaining this file

- Update it when a genuinely cross-repo convention emerges; brief the owner on the addition. Keep it concise, public-safe, and duplication-free. Project-specific rules go in the project's own `CLAUDE.md`, never here.
