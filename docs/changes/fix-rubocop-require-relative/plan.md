# Plan: Make the linter pass on main again

From `intent.md` and `spec.md` (2026-09-29). Status: accepted.

## Context

`bundle exec rubocop` on `main` (`3c8eef6`) fails with 7 `Packaging/RequireRelativeHardcodingLib` offenses. The rule arrived through the shared `rubocop-eirvandelden` rules when commit `6254292` moved their locked revision. Because of the failures, every new branch starts with a failing lint check and commits and pull requests are blocked. There are two kinds of offense:

- `applications/ambilight/ambilight.rb:9`, `applications/setcolor/setcolor.rb:1`, `applications/setcolor/setfan.rb:1`, `examples/test-loop/test-loop.rb:5` use `require_relative "../../lib/libambx"`. These scripts are not in the gem and run from a checkout with plain `ruby`, so `require_relative` is the correct way for them to load the library.
- `spec/ambx_spec.rb:5,6,161` use `require_relative "../libcombustd/..."`. These are false positives. The rule (rubocop-packaging 0.6.0, `lib_helper_module.rb:15`) checks `start_with?("#{root_dir}/lib")`, so `libcombustd/` matches as if it were `lib/`.

Accepted decisions (spec D1, D2): exclude `applications/**/*`, `examples/**/*` and `spec/ambx_spec.rb` from that one rule in `.rubocop.yml`, each with a one-line reason. No code changes and no disable comments. The shared config has no cop-level `Exclude` for `Packaging/RequireRelativeHardcodingLib`, so a local `Exclude` doesn't override any inherited list.

## Where to run the linter

Run every linter check from a fresh clone of the branch outside this repository: `git clone -q --no-local --branch fix-rubocop-require-relative <worktree> <scratch>/fresh`, then `bundle exec rubocop` inside it. RuboCop takes the outermost `Gemfile` above the working directory as the project root (`ConfigFinder#find_project_root` uses `find_last_file_upwards`). Inside `.worktrees/` that is the main checkout, so the rule compares paths against the main checkout's `lib/` and reports nothing. A fresh clone is also what CI sees.

## Files that change

- `.rubocop.yml`: add a `Packaging/RequireRelativeHardcodingLib` block with an `Exclude` list for the three paths, plus a comment before each explaining why.
- `docs/changes/fix-rubocop-require-relative/{intent,spec,plan}.md`: the change artifacts.

Nothing else changes. `.rubocop.yml` isn't in `spec.files`, so the gem's contents can't change.

## Order of work

1. Acceptance (walking skeleton): run `bundle exec rubocop` in a fresh clone and watch it fail with exactly the 7 `Packaging/RequireRelativeHardcodingLib` offenses listed above.
2. Commit the change artifacts (`docs/changes/...`) on their own.
3. Add the `Exclude` entries for `applications/**/*` and `examples/**/*` with their reason. Run rubocop again: the 3 `spec/ambx_spec.rb` offenses remain.
4. Add the `Exclude` entry for `spec/ambx_spec.rb` with its reason (the rule reads `libcombustd/` as `lib/`). Run rubocop: "no offenses detected".
5. Run `bundle exec rake test`: both test tasks green.
6. Check A2 without hardware. `ruby applications/setcolor/setcolor.rb 0 0 0`, `ruby applications/setcolor/setfan.rb 0` and `ruby examples/test-loop/test-loop.rb` (each under `timeout 10`) must not raise `LoadError`. `applications/ambilight/ambilight.rb` takes screenshots in a loop and needs `ruby-vips`, so for that one run `ruby -e 'require_relative "applications/ambilight/../../lib/libambx"'` from the repository root to prove its load line resolves, and confirm the file itself is unchanged.
7. Run `git grep -n "rubocop:disable"` and compare it to `main`: nothing new.
8. Re-read the full diff. Commit `.rubocop.yml` as one commit: `chore: keep the packaging rule off scripts and its own false positive`.
9. Run the `review` skill (report-only), then push the branch and open a PR against `origin` (`eirvandelden/libamBX`).

## Risks

- A bad glob would leave offenses in place, or hide more than intended. Step 3's run proves the script exclusions separately from step 4's.
- The exclusion also hides future real offenses in the excluded files. That's accepted for scripts that aren't in the gem. For `spec/ambx_spec.rb` it's limited to that one file, not all of `spec/`.
- Rejected: accepting the automatic correction (writes this machine's absolute path into the spec). Rejected: adding `.` to the Rakefile load path (breaks running the spec file directly, and resolves through `lib/libcombustd/` first). Rejected: `$LOAD_PATH.unshift` in each script (the author chose D2(a)).

## Proof

- A1 (linter clean) → `bundle exec rubocop` in a fresh clone reports "no offenses detected"
- A2 (scripts still load) → step 6 commands exit without `LoadError`
- A3 (tests green, one-at-a-time loading intact) → `bundle exec rake test` (`test:ambx`, `test:gem_package`), with `spec/ambx_spec.rb` unchanged
- A4 (no disable comments) → `git grep -n "rubocop:disable"` output matches `main`
- A5 (gem contents unchanged) → `spec/gem_package_spec.rb` `test_built_gem_contains_driver_and_attribution_without_applications_or_tests`, plus `.rubocop.yml` being absent from `spec.files` in `libambx.gemspec`

Per changed file, unit tests: none. `.rubocop.yml` is lint configuration, and the linter run itself is the test (the agile rule's "no test needed for config" exception).

Test setup: none. No hardware needed.

## Out of scope

- Reporting the prefix bug upstream to `rubocop-packaging`.
- Hardware check of the 0.4.1 USB context fix, and moving the ambx2mqtt pin.
- The `Device#transfer`/`close_handle` unplug error handling.
- Any change to the scripts, the spec file, the Rakefile or CI workflows.
