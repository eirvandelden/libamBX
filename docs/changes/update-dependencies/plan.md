# Plan: Update dependencies to their latest versions

From `intent.md` (2026-10-06). Status: accepted.

## Context

On 2026-10-06, `bundle outdated` lists 18 gems behind their latest release. Two are a major version behind: brakeman 7.1.0 → 8.1.0 and json 2.21.2 → 3.0.2. The lockfile says `BUNDLED WITH 2.7.2`; the latest Bundler is 4.0.22. CI tests on Ruby 3.4; the latest is 4.0.7. The Rubocop workflow triggers only on the deleted `combustd-ruby-dev` branch, so it never runs.

The outcome: every locked gem at its latest release, Bundler 4.0.22, a Ruby 4.0 floor, CI on Ruby 4.0, both workflows on their latest action majors, the Rubocop workflow running on `main`, and the gem at 0.5.0 with a CHANGELOG entry.

Baseline, measured on 2026-10-06 in this worktree with Ruby 4.0.7 and the current lockfile: `bundle exec rake test` is green (23 + 3 runs). `brakeman --force-scan` finds no warnings.

The 18 outdated gems include: activesupport 8.1.3.1 → 8.1.4, brakeman 7.1.0 → 8.1.0, bundler-audit 0.9.2 → 0.9.3, ffi 1.16.3 → 1.17.4, json 2.21.2 → 3.0.2, libusb 0.7.1 → 0.8.0, parallel 2.1.0 → 2.3.0, regexp_parser 2.12.0 → 2.13.1, rubocop 1.90.0 → 1.91.0, rubocop-eirvandelden a168e3d → 1e2e033, rubocop-minitest 0.40.0 → 0.41.0, rubocop-rails 2.37.0 → 2.38.0, ruby-vips 2.2.4 → 2.3.0, thor 1.4.0 → 1.5.0, unicode-display_width 3.2.0 → 3.3.0, unicode-emoji 4.2.0 → 4.3.0. The other two are patch releases: the decimal-number gem and the native-build helper that libusb depends on. Step 1 records the full list.

## Design decisions

- D1. Bundler 4.0.22 is not installed on this machine; 4.0.21 is the newest local one. Etienne gave explicit permission on 2026-10-06: the implementer may let `bundle update --bundler` download and install Bundler 4.0.22 into rv's gem home. That permission covers only that one gem. It does not cover a Ruby, rv, or any other tool.
- D2. bundler-audit moves to 0.9.3 before Bundler moves to 4. Version 0.9.2 declares `bundler (>= 1.2.0, < 3)`, so it blocks Bundler 4. Version 0.9.3 declares `bundler (>= 1.2.0)`.
- D3. The Rubocop job fails on any offense (Etienne's choice, 2026-10-06). The current step wraps RuboCop in `bash -c "... [[ $? -ne 2 ]]"`. The outer shell expands `$?` to 0 before RuboCop runs, so the step always passes. The new step drops the `bash -c` wrapper. It runs the same `bundle exec rubocop` command, with the same `--require`, `--format` and `-o` arguments, and adds `--format progress`. RuboCop's own exit code then fails the step. The upload step gets `if: ${{ !cancelled() }}`, so the scan report still uploads when RuboCop reports offenses. In this plan, "scan report" means the code-scanning file that the current step writes with `-o`.
- D4. The Rubocop workflow's `setup-rv` step gets `ruby-version: "4.0"`. Without that input, setup-rv installs no Ruby. Then `bundle install` runs on the runner's system Ruby, and the new `>= 4.0` floor refuses it. `rv ruby install 4.0` picks the latest 4.0 release.
- D5. `spinel-coop/setup-rv@main` becomes `@v1`. `v1` is the only tag, so it is the latest major. A tag is what the intent asks for: "latest major version".
- D6. INSTALL says "Ruby 3.1 or newer". It changes to "Ruby 4.0 or newer" in the same commit that raises the floor (Etienne's choice, 2026-10-06).
- D7. One commit per logical bump: bundler-audit, Bundler, brakeman, json, libusb, the RuboCop set, then the rest. When a later step breaks, the commit shows which bump caused it. The intent approves a full `bundle update`; it runs last, only to catch what the targeted updates left behind.
- D8. The version bump to 0.5.0 and its CHANGELOG entry come last, so the entry describes the final state.
- D9. The Rubocop workflow file has yamllint errors today: bracket spacing, a missing `---`, and step indentation. The pre-commit hook runs yamllint on staged YAML, so the commit that first touches that file fixes them. The new trigger block uses the same `branches: [main]` form as `test.yml`. The dead commented-out `schedule` and the "subset of the branches above" comment go with the old trigger block.
- D10. Brakeman runs with `--force-scan`. Without it, Brakeman exits with "Please supply the path to a Rails application", because this is a plain gem. The consent-guard hook blocks the literal `--force` (it reads it as a git force push), so do not use that spelling.
- D11. Gemfile and gemspec constraints stay as they are. The `dependencies` skill says not to pin versions by default. No gem is added or removed.

## Integration points

- gem.coop: the gem source for every update.
- GitHub `eirvandelden/rubocop-eirvandelden`: the `GIT` source in the lockfile. Between `a168e3d` and `1e2e033`, only `config/rspec.yml` and repository docs changed, so `config/default.yml` brings no new cops. Check again at implement time, because main can move.
- GitHub Actions: `actions/checkout` (latest major v7), `ruby/setup-ruby` (v1), `spinel-coop/setup-rv` (v1), and the CodeQL upload action from `github/codeql-action` (v4). The code-scanning-rubocop gem is at 0.6.1 on gem.coop and declares `rubocop (~> 1.0)`.
- Code scanning: the scan report upload needs `security-events: write`. The repository is public and its default workflow token permission is `write`, so pull requests from branches in this repository can upload.
- The amBX hardware, through libusb 0.8.0. Its changelog adds APIs and updates the bundled libusb to 1.0.30, with no removals. The driver uses only `LIBUSB::Context`, `LIBUSB::ERROR_BUSY` and `LIBUSB::ERROR_NOT_FOUND`.
- `ambx2mqtt` picks up 0.5.0 later, through its own `bundle update libambx`. That is out of scope here.

## Files that change

- `Gemfile.lock`: every gem at its latest release, `rubocop-eirvandelden` at the latest default-branch commit, `BUNDLED WITH 4.0.22`, and `libambx (0.5.0)` in `PATH` and `CHECKSUMS`.
- `libambx.gemspec`: `required_ruby_version = ">= 4.0"`.
- `spec/gem_package_spec.rb`: the floor assertion expects `">= 4.0"`; the version assertion expects `"0.5.0"`.
- `lib/libambx/version.rb`: `VERSION = "0.5.0"`.
- `CHANGELOG`: a new `# Version 0.5.0` entry at the top. It says the gem now requires Ruby 4.0 and that Ruby 3.4 callers must stay on 0.4.1. It also says libusb moved to 0.8.0.
- `INSTALL`: "Ruby 3.1 or newer" becomes "Ruby 4.0 or newer" (D6).
- `.github/workflows/test.yml`: `ruby-version: "4.0"`, `actions/checkout@v7`.
- `.github/workflows/rubocop.yml`: trigger on push and pull request to `main`, `actions/checkout@v7`, `spinel-coop/setup-rv@v1` with `ruby-version: "4.0"`, `code-scanning-rubocop --version 0.6.1`, the direct RuboCop step (D3), and the CodeQL upload action at `@v4` with `if: ${{ !cancelled() }}`. yamllint-clean (D9).
- Any Ruby file that the updated RuboCop flags, fixed without changing behavior. Which files is unknown until the linter runs.

## Order of work

Commit rules for every step: commit only the files the step names. A commit that stages `.md` or `.rb` files needs `PATH="$HOME/.nodes/node-22.21.1/bin:$PATH" git commit ...`. The spelling hook needs cspell, which only that Node has. Never use `--no-verify`.

Lint rule for every step: run RuboCop from a fresh clone, never inside `.worktrees/`. Inside a worktree, RuboCop takes the main checkout as project root, and the Packaging cops silently pass. Commit first, then run `git clone -q --no-local --branch update-dependencies <worktree> <scratchpad>/fresh`, then `bundle install && bundle exec rubocop` inside it.

1. Walking skeleton: run `bundle outdated`. Watch it exit 1 and list the 18 gems above. Save the list for the pull request body.
2. Ruby 4.0 floor. In `spec/gem_package_spec.rb`, change the floor assertion to `Gem::Requirement.new(">= 4.0")`. Run `bundle exec rake test:gem_package` and watch `test_gemspec_describes_the_libambx_package` fail on the requirement. Set `required_ruby_version = ">= 4.0"` in `libambx.gemspec`. Run it again: green. Change `ruby-version` in `test.yml` to `"4.0"`. Change the Ruby sentence in `INSTALL`. Commit: `chore: require Ruby 4.0`.
3. `bundle update bundler-audit`. Check that the lockfile shows 0.9.3. Run `bundle exec rake test` and `bundle exec bundle-audit check --update`. Commit `Gemfile.lock`: `chore: update bundler-audit to 0.9.3`.
4. Check the latest Bundler on gem.coop: `gem search --remote --source https://gem.coop/ '^bundler$'`. Run `bundle update --bundler` (D1). Check that the lockfile ends in `BUNDLED WITH 4.0.22`, or the newer release found. Run the test suite and bundle-audit again. Commit: `chore: bundle with Bundler 4.0.22`.
5. `bundle update brakeman` (7.1.0 → 8.1.0, one major). Run `bundle exec brakeman --force-scan --no-pager --no-progress -q` and expect "No warnings found". Commit: `chore: update brakeman to 8`.
6. `bundle update json` (2.21.2 → 3.0.2, one major). Run the test suite and RuboCop from a fresh clone; RuboCop is the only json consumer. Commit: `chore: update json to 3`.
7. `bundle update libusb`. This also moves ffi and libusb's native-build helper gem. Run the test suite. Commit: `chore: update libusb to 0.8.0`.
8. `bundle update rubocop-eirvandelden`. This unlocks rubocop, rubocop-minitest, rubocop-rails and their dependencies. Check that the lockfile `revision:` equals `git ls-remote https://github.com/eirvandelden/rubocop-eirvandelden.git HEAD`. Commit `Gemfile.lock`: `chore: update the RuboCop rules and plugins`.
9. Run RuboCop from a fresh clone. If it reports offenses, fix them in the worktree without changing behavior and without disable comments. Run the test suite after each fix. Commit the fixes on their own: `style: fix offenses from RuboCop <version>`. Skip this step when there are no offenses.
10. Run `bundle update` once for whatever remains (approved in the intent). Run `bundle outdated` and expect exit 0, "Bundle up to date!". When a gem cannot reach its latest release, note the gem and what holds it back for the pull request body. Commit: `chore: update the remaining gems`.
11. Deprecations: the Rakefile sets `task.warning = false`, so run each spec file directly once with `bundle exec ruby -W:deprecated -Ilib spec/<file>`. Fix every deprecation that this project's own code triggers, each in its own commit with the test suite green. Ignore warnings from outside the project: the "already initialized constant" warnings from two installed documentation gems come from this machine's gem home.
12. Spike code-scanning-rubocop 0.6.1 in a fresh clone, with gems kept out of the shared gem home: `BUNDLE_PATH=<scratchpad>/vendor bundle add code-scanning-rubocop --version 0.6.1 --skip-install`, then `bundle install`, then the RuboCop command from the current workflow step, with `--format progress` added (D3). Expect exit 0 and a scan report that parses as JSON. If the formatter fails on RuboCop 1.91 or Ruby 4.0, stop and report. Do not swap in another gem.
13. Make the Rubocop workflow run. In `rubocop.yml`: replace the trigger block with push and pull request on `branches: [main]` (D9). Add `ruby-version: "4.0"` to the setup-rv step (D4). Fix the yamllint errors (D9). Run `yamllint .github/workflows/*.yml`: no errors and no warnings. Commit: `ci: run the Rubocop workflow on main`.
14. Make the Rubocop job fail on offenses (D3). Replace the `bash -c` block with the bare `bundle exec rubocop` command it wraps, with `--format progress` added. Add `if: ${{ !cancelled() }}` to the upload step. Run yamllint. Commit: `ci: fail the Rubocop job on offenses`.
15. Action majors. First re-check the latest release of each action with `gh api repos/<owner>/<repo>/releases/latest` (setup-rv has tags only: `gh api repos/spinel-coop/setup-rv/tags`). Then set `actions/checkout@v7` in both files, `spinel-coop/setup-rv@v1`, the CodeQL upload action at `@v4`, and `--version 0.6.1` on the code-scanning-rubocop step. Keep `ruby/setup-ruby@v1`. Run yamllint. Commit: `ci: move workflow actions to their latest majors`.
16. Release 0.5.0. In `spec/gem_package_spec.rb`, change the version assertion to `"0.5.0"`. Run `bundle exec rake test:gem_package` and watch `test_canonical_entry_point_loads_the_driver_and_version` fail with "0.4.1". Set `VERSION = "0.5.0"`. Run `bundle install` so the lockfile records `libambx (0.5.0)`. Add the CHANGELOG entry. Run the test suite: green. Commit: `chore: release 0.5.0`.
17. Ruby 3.4 refusal. Run `gem build libambx.gemspec --output <scratchpad>/libambx-0.5.0.gem`. Then run `~/.local/share/rv/rubies/ruby-3.4.8/bin/gem install --local --ignore-dependencies --install-dir <scratchpad>/gems34 <scratchpad>/libambx-0.5.0.gem`. Expect a failure that says libambx requires Ruby version >= 4.0. Then run the same install with `~/.local/share/rv/rubies/ruby-4.0.7/bin/gem` and `--install-dir <scratchpad>/gems40`, and expect success. Both Rubies are already installed; install nothing.
18. Full local check: `bundle exec rake test`, RuboCop from a fresh clone, `bundle exec brakeman --force-scan --no-pager --no-progress -q`, `bundle exec bundle-audit check --update`, `bundle outdated` (exit 0), `yamllint .github/workflows/*.yml`. Compare `git grep -n "rubocop:disable"` with `main`: nothing new. Re-read the full diff against `main`; every hunk must belong to this plan.
19. Run the `review` skill (report-only). Push and open a pull request against `origin` (`eirvandelden/libamBX`), base `main`. The repository has no PR template. The body lists the 18 gems with their old and new versions, and any gem held back with its reason.
20. Watch the pull request checks. The Test job must run on Ruby 4.0.x and pass, including `gem build`. The Rubocop job must run and pass, and its scan report upload must succeed. Fix any failure in a new commit; never weaken a check.
21. Hardware: Etienne connects an amBX and runs `bundle exec ruby applications/setcolor/setcolor.rb 255 0 0` from the worktree. The lights must turn red. Then `... 0 0 0` turns them off.

## Risks

- `rv ci` in the Rubocop workflow could fail to read a Bundler 4 lockfile. Step 20's CI run proves it. When it fails, report it; do not downgrade Bundler.
- code-scanning-rubocop 0.6.1 dates from 2022 and could break on RuboCop 1.91 or Ruby 4.0. Step 12 finds that out before CI does.
- The scan report upload fails on pull requests from forks, because their token is read-only. Accepted: none are expected, and the intent does not ask for fork support.
- The updated RuboCop can bring new offenses. Fixes must keep behavior; `spec/ambx_spec.rb` (23 runs) guards the driver.
- libusb 0.8.0 changes nothing the driver calls, but only the hardware check in step 21 proves the USB path.
- ffi 1.17 on the Linux runner: the lockfile has only `arm64-darwin` and `ruby` platforms, so CI compiles ffi from source, as it does today with 1.16.3.
- Releases can land between this plan and the merge. Step 18 runs `bundle outdated` again just before the push.
- Callers on Ruby 3.4 can no longer install 0.5.0. The intent accepts this; the CHANGELOG tells them to stay on 0.4.1.
- Rejected: one big `bundle update` commit, because it hides which bump broke what. Rejected: `bundle update --conservative`, because it holds transitive gems back. Rejected: a `.ruby-version` file for setup-rv, because the `ruby-version` input does the job without a new file. Rejected: replacing setup-rv with `ruby/setup-ruby` in the Rubocop workflow, because the intent asks for version bumps, not a different action.

## Proof

- `bundle outdated` reports no outdated gem → `bundle outdated` exits 0 with "Bundle up to date!" (steps 10 and 18). Any held-back gem is named in the pull request body.
- `BUNDLED WITH 4.0.22` or newer → `tail -2 Gemfile.lock`, compared with `gem search --remote --source https://gem.coop/ '^bundler$'` (step 4).
- `rubocop-eirvandelden` at the latest default-branch commit → the lockfile `revision:` equals `git ls-remote https://github.com/eirvandelden/rubocop-eirvandelden.git HEAD` (step 8).
- 0.5.0 refuses Ruby 3.4 and installs on Ruby 4.0 → `spec/gem_package_spec.rb` `test_gemspec_describes_the_libambx_package` (asserts `>= 4.0`), plus the two `gem install` runs in step 17.
- The Test workflow runs on Ruby 4.0 and passes, including the gem build → the pull request's Test check, with Ruby 4.0.x in its setup step log (step 20).
- The Rubocop workflow runs on the pull request to `main` and passes → the pull request's Rubocop check (step 20).
- Every action at its latest major, code-scanning-rubocop at its latest release → `grep -n -E 'uses:|code-scanning-rubocop' .github/workflows/*.yml` shows `checkout@v7`, `setup-ruby@v1`, `setup-rv@v1`, the CodeQL upload action at `@v4` and `--version 0.6.1`, matching the releases checked in step 15.
- Locally, tests, RuboCop, Brakeman and bundler-audit are all clean → the commands in step 18.
- The lights respond on real hardware → Etienne's setcolor run in step 21.
- `Libambx::VERSION` is "0.5.0" and the CHANGELOG says Ruby 4.0 is required → `spec/gem_package_spec.rb` `test_canonical_entry_point_loads_the_driver_and_version` (asserts "0.5.0"), plus a read of the CHANGELOG's top entry.

Per changed file, the unit tests expected:

- `spec/gem_package_spec.rb`: no new tests. Two existing assertions change: `test_gemspec_describes_the_libambx_package` expects `>= 4.0`, and `test_canonical_entry_point_loads_the_driver_and_version` expects "0.5.0".
- `libambx.gemspec`, `lib/libambx/version.rb`: covered by the two tests above.
- `Gemfile.lock`: no unit test. The full suite plus the step commands prove each bump.
- `.github/workflows/*.yml`, `INSTALL`, `CHANGELOG`: no unit test. They are configuration and prose. yamllint and the pull request's CI runs prove the workflows.
- Ruby files changed for RuboCop offenses or deprecations: no new tests. The changes keep behavior, and the existing `spec/ambx_spec.rb` covers them. If a fix would change behavior, stop and report instead.

Test setup: none new. No fixtures, no hardware for the automated suite. Step 17 uses the two Rubies rv already has. Step 21 needs Etienne and a connected amBX.

## Out of scope

- Behavior changes to the driver.
- Updating `ambx2mqtt` to the new revision.
- The Dependabot configuration.
- Publishing to RubyGems, and correcting `docs/releasing.md` or the README's "After a RubyGems release" wording.
- Supporting Ruby 3.4 alongside 4.0.
- Installing any Ruby, rv, or system tool. The only allowed install is Bundler 4.0.22 through `bundle update --bundler` (D1).
- Fork pull request support for the scan report upload.
- Adding Linux platforms to the lockfile.
- The Ruby 3.1 mention in `docs/superpowers/plans/2026-08-25-libambx-multi-device.md`, a historic document.
- The untracked files in the main checkout, and open PR #7.

---
Domain skills applied: dependencies, rails-testing (Minitest conventions only; this is not a Rails app).
