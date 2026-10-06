# Intent: Update dependencies to their latest versions

Author: Etienne van Delden de la Haije. Status: accepted. Type: chore.

## Problem

The project has drifted behind its dependencies. On 2026-10-06, `bundle outdated` lists 18 gems behind their latest release, two of them a major version behind (brakeman 7 → 8, json 2 → 3). The lockfile is bundled with Bundler 2.7.2; the latest is 4.0.22. CI tests on Ruby 3.4; the latest is 4.0.7. The workflows use `actions/checkout@v3` and `@v4`, the CodeQL upload action from `github/codeql-action` at `@v2`, and pin `code-scanning-rubocop` to 0.3.0.

Each release skipped makes the next upgrade larger and riskier. The security tools (brakeman, bundler-audit) also miss the checks their newer releases ship.

The Rubocop workflow never runs: it triggers only on the `combustd-ruby-dev` branch, which no longer exists. Lint regressions can reach `main` without CI noticing.

## Proposed outcome

Every dependency the project declares or locks is at its latest release. CI tests the gem on Ruby 4.0, the only Ruby it supports. The Rubocop workflow runs on pull requests to `main` and passes. The gem ships as 0.5.0, and its CHANGELOG tells callers they now need Ruby 4.0.

## Affected users and systems

- Callers of the gem, chiefly `ambx2mqtt`, which depends on it from GitHub. It already runs Ruby 4.0.6.
- Anyone still on Ruby 3.4: they can no longer install 0.5.0.
- The physical amBX hardware, through the `libusb` runtime dependency (0.7.1 → 0.8.0).
- The GitHub Actions workflows `test.yml` and `rubocop.yml`.
- Developers who run `bundle install`, the test suite, and the linters locally.

## Constraints

- Never skip a major version. Brakeman 7 → 8, json 2 → 3, and Ruby 3.4 → 4.0 are each one step. Bundler 2.7 → 4.0 skips nothing, because Bundler 3 was never released.
- Updating all gems at once is explicitly approved for this change (playbook rule 11).
- Changing `.github/workflows/` is explicitly approved for this change (playbook rule 13).
- Ruby 4.0.7 is already installed through `rv` and is the default. No toolchain install is needed (rule 8).
- Gems come from `gem.coop`. `rubocop-eirvandelden` stays on GitHub, unversioned, tracked by SHA.
- No gem is added to or removed from the Gemfile or gemspec.
- The gem is not published to RubyGems. A merge to `main` is the release.
- New offenses from the updated linters are fixed in this change. No linter disable comments.

## In scope

- Every gem in `Gemfile.lock`, direct and transitive, updated to its latest release, including the major bumps.
- `rubocop-eirvandelden` updated to the latest commit on its default branch.
- `BUNDLED WITH` updated to the latest Bundler.
- The Ruby floor in `libambx.gemspec` raised to 4.0, and CI moved to Ruby 4.0.
- Every action in `test.yml` and `rubocop.yml` moved to its latest major version.
- The `code-scanning-rubocop` version pinned in `rubocop.yml` moved to its latest release.
- The Rubocop workflow triggered on pushes and pull requests to `main`, so it runs and passes.
- Any code or test change the new versions force: deprecations, removed APIs, new lint offenses.
- `lib/libambx/version.rb` set to 0.5.0, with a 0.5.0 CHANGELOG entry.

## Out of scope

- Behavior changes to the driver.
- Updating `ambx2mqtt` to pick up the new revision.
- The Dependabot configuration.
- Publishing to RubyGems, and correcting `docs/releasing.md`.
- Supporting Ruby 3.4 alongside 4.0.
- Installing any Ruby, Bundler, or system tool on this machine.
- The untracked files in the main checkout (`bin/`, `yarn.lock`, `screenshot.png`, `docs/handoffs/`). The repo has no `package.json`, so there are no Node dependencies to update.
- Open PR #7 (rotary gear support).

## Acceptance criteria

- Running `bundle outdated` reports no outdated gem. If a gem cannot reach its latest release, the pull request names the gem and the dependency that holds it back.
- `Gemfile.lock` reads `BUNDLED WITH 4.0.22`, or a newer release if one ships before the merge.
- `rubocop-eirvandelden` is locked to the latest commit on its default branch.
- Installing libambx 0.5.0 on Ruby 3.4 fails with a Ruby version error. On Ruby 4.0 it installs.
- The Test workflow runs on Ruby 4.0 on the pull request and passes, including the gem build.
- The Rubocop workflow runs on the pull request to `main` and passes.
- Every action the two workflows use is at its latest major version, and `code-scanning-rubocop` is at its latest release.
- Locally, the test suite passes, RuboCop reports no offenses, Brakeman reports no warnings, and bundler-audit reports no advisories.
- With an amBX connected, Etienne runs a color change and sees the lights respond.
- `Libambx::VERSION` is "0.5.0", and the CHANGELOG's 0.5.0 entry says the gem now requires Ruby 4.0.

## Flagged concerns

- Compatibility against currency: raising the floor to Ruby 4.0 locks out any caller still on 3.4. Chosen side: drop 3.4. The only known caller, `ambx2mqtt`, already runs 4.0.6, and the version bump plus CHANGELOG entry warn the rest.
- Scope against focus: fixing the Rubocop trigger is a CI fix, not a version bump. Chosen side: include it. Without it, the bumped Rubocop actions can never be shown to work.

## Open questions

None.
