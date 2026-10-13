# Review: update-dependencies

## Round 1 — 2026-10-13T08:20Z — 3cd4b27

The repository has no `REVIEW.md` or `REVIEW.local.md`. This round uses the default Bugs, Security and Compliance passes.

Checks run on 3cd4b27: `bundle exec rake test` green. RuboCop from a fresh clone: 19 files, no offenses, no new `rubocop:disable`. Brakeman `--force-scan`: no warnings. `bundle-audit check --update`: no vulnerabilities. `yamllint .github/workflows/*.yml`: clean. `-W:deprecated` on each spec file: no project deprecations. The CI RuboCop step, spiked in a fresh clone with code-scanning-rubocop 0.6.1: exit 0, and the scan report parses as JSON (format version 2.1.0). `bundle outdated`: exit 1 (see the first finding).

### Findings

- [ ] Important: `bundle outdated` exits 1 again. Two releases shipped after step 10: json 3.0.2 → 3.1.0 and rubocop 1.91.0 → 1.92.0. The first acceptance criterion fails, and the CHANGELOG line "Update every other dependency to its latest release" (`CHANGELOG:7`) is now untrue. Plan step 18 asks for this re-check before the push. RuboCop 1.92 can bring new cops, so run the fresh-clone lint again after the update. — `Gemfile.lock:53`, `Gemfile.lock:74` →
- [ ] Nit: Security. The Rubocop workflow has no `permissions:` block. It now runs on every push to `main` and every pull request, and it installs gems and builds native extensions (ffi) with the repository's default write-all token. Declare `contents: read` and `security-events: write` for the job. `test.yml` has the same gap, already live before this branch. — `.github/workflows/rubocop.yml:16` →
- [ ] Nit: Security. `spinel-coop/setup-rv@v1` is a third-party action on a mutable tag. `@v1` is safer than the old `@main`, but a commit SHA with a `# v1` comment still satisfies "latest major" and cannot move under the workflow. — `.github/workflows/rubocop.yml:27` →
- [ ] Nit: The step 17 command does not test Ruby 3.4. `~/.local/share/rv/rubies/ruby-3.4.8/bin/gem` starts with `#!/usr/bin/env ruby`, so in an rv shell it runs Ruby 4.0.7, and 0.5.0 installs "successfully". With a clean environment, `env -i HOME=$HOME PATH=$R:/usr/bin:/bin $R/gem install --local --ignore-dependencies --no-document --install-dir <dir> libambx-0.5.0.gem` (where `$R` is the 3.4.8 `bin`) fails as expected: "libambx-0.5.0 requires Ruby version >= 4.0. The current ruby version is 3.4.8." Use the clean-environment run as the evidence in the pull request. — `docs/changes/update-dependencies/plan.md:72` →
- [ ] Nit: The new CHANGELOG list items are hard-wrapped. Playbook rule 26 asks for one line per list item, even in a file that is already hard-wrapped. — `CHANGELOG:3` →

### Compliance

| Acceptance criterion (intent.md) | Proof | Status |
| --- | --- | --- |
| `bundle outdated` reports no outdated gem | `bundle outdated` | Fails: json 3.1.0, rubocop 1.92.0 |
| `BUNDLED WITH 4.0.22` or newer | `Gemfile.lock` tail vs `gem search` on gem.coop (latest 4.0.22) | Met |
| `rubocop-eirvandelden` at the latest default-branch commit | lockfile `revision:` = `git ls-remote` HEAD `1e2e033` | Met |
| 0.5.0 refuses Ruby 3.4 and installs on Ruby 4.0 | `test_gemspec_describes_the_libambx_package` asserts `>= 4.0`; clean-environment `gem install` on 3.4.8 refused, on 4.0.7 installed | Met |
| Test workflow runs on Ruby 4.0 on the PR and passes, including the gem build | Pull request Test check | Missing: branch not pushed (`origin/update-dependencies` is at b003180), no pull request yet |
| Rubocop workflow runs on the PR to `main` and passes | Pull request Rubocop check | Missing: same reason; the local spike passed |
| Every action at its latest major; code-scanning-rubocop at its latest release | checkout v7 (latest v7.0.1), setup-ruby v1, setup-rv v1 (only tag), codeql-action v4 (highest major tag), code-scanning-rubocop 0.6.1 (latest on gem.coop) | Met |
| Locally: tests, RuboCop, Brakeman, bundler-audit clean | Commands listed above | Met |
| The lights respond on real hardware | Etienne's setcolor run, plan step 21 | Missing: no evidence recorded yet |
| `Libambx::VERSION` is "0.5.0"; the CHANGELOG says Ruby 4.0 is required | `test_canonical_entry_point_loads_the_driver_and_version` asserts "0.5.0"; CHANGELOG 0.5.0 entry | Met |

Both tests named in the plan's `## Proof` exist in `spec/gem_package_spec.rb`. Their two changed assertions track the new floor and version. No test was weakened, skipped or deleted. Every commit holds one logical change and only files from the plan.
