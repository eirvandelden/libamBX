# Spec: Make the linter pass on main again

From `intent.md` (2026-09-29). Status: accepted.

## Flagged concerns

- The intent forbids lint disable comments (playbook rule 2). Excluding files from a rule in `.rubocop.yml` works the same way, just in one central place. Rule 21 also lists lint configs as something to keep out of unrelated commits. This change is about linting, so a config edit is in scope, but it still switches the rule off for those files. The alternative for the scripts, adding `lib` to the load path by hand, keeps the rule on while doing the same thing `require_relative` did. The rule only fails to notice it. Decision D2 picks the config exclusion, chosen by the author.

## Requirements

- R1. `bundle exec rubocop` reports no offenses on a fresh checkout.
- R2. Each script in `applications/` and `examples/` still loads the library when run from a checkout with plain `ruby <path>`, with no `-Ilib` and no `bundle exec`.
- R3. The driver tests still load the driver files one at a time, around the fake USB library they define, and pass under `bundle exec rake test`.
- R4. No lint disable comments are added anywhere.
- R5. The published gem contains exactly the same files as before.

## Design decisions

- D1. `spec/ambx_spec.rb` gets excluded from `Packaging/RequireRelativeHardcodingLib` in `.rubocop.yml`, with a one-line comment giving the reason: the rule treats `libcombustd/` as `lib/`. The code doesn't change. The other two routes are worse. Switching to `require "libcombustd/..."` with `.` on the Rakefile load path breaks running the test file directly, and it would resolve through `lib/libcombustd/` first. Accepting the automatic correction writes an absolute path from this machine into the file.
- D2. `applications/**/*` and `examples/**/*` are excluded from the same rule in `.rubocop.yml`. These scripts are not part of the gem, and `require_relative` into the checkout is the correct way to load the library for scripts that only run from a checkout. With D1, every exception sits in one place, each with its reason. Chosen over adding `lib` to the load path inside each script, which does the same thing in more code and avoids the rule only because the rule cannot see it.

## Integration points

- `.rubocop.yml`, which inherits the shared `rubocop-eirvandelden` rules.
- `applications/ambilight/ambilight.rb`, `applications/setcolor/setcolor.rb`, `applications/setcolor/setfan.rb`, `examples/test-loop/test-loop.rb` (unchanged; excluded by D2).
- The CI `rubocop` workflow, which runs the same linter. The workflow itself doesn't change.

## Acceptance criteria

- A1 (R1). Running the linter on a fresh checkout reports "no offenses detected".
- A2 (R2). Running each of the four scripts with plain `ruby` from the repository root gets past loading the library. It doesn't stop with a `LoadError` for `libambx`.
- A3 (R3). The driver tests and the gem package tests pass under `bundle exec rake test`, and `spec/ambx_spec.rb` still loads each driver file on its own.
- A4 (R4). Searching the repository for `rubocop:disable` finds nothing new.
- A5 (R5). The file list of a built gem is identical before and after the change.

---
Domain skills applied: dependencies (shared lint rules come from a personal gem; no dependency added or removed), ruby-style.
