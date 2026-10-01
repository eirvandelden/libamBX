# Intent: Make the linter pass on main again

Author: Etienne van Delden de la Haije. Status: accepted. Type: chore.

## Problem

The linter fails on `main`, so every new branch starts with a failing lint check and commits and pull requests are blocked until it passes. The failures are seven `Packaging/RequireRelativeHardcodingLib` offenses that appeared when the shared rules (`rubocop-eirvandelden`) moved to a newer revision in `6254292`:

- Four are real: the scripts in `applications/` and `examples/` load the library with `require_relative "../../lib/libambx"`.
- Three in `spec/ambx_spec.rb` are false: the rule compares paths by text prefix, so it takes `libcombustd/` for `lib/`. Its automatic correction would write an absolute path from this machine into the test file.

## Proposed outcome

`bundle exec rubocop` reports no offenses on a fresh checkout of `main`, with no lint disable comments.

## Affected users and systems

- Anyone committing to or opening a pull request against this repository.
- The scripts in `applications/` and `examples/`.
- The driver tests in `spec/ambx_spec.rb`.

## Constraints

- The scripts in `applications/` and `examples/` must still run from a checkout with plain `ruby applications/...`, without `-Ilib` or `bundle exec`.
- The driver tests must still load the driver files one at a time, around the fake USB library they define, and stay green.
- No lint disable comments.
- The published gem's contents do not change.

## Open questions

- Should the false positive in the rule also be reported upstream to `rubocop-packaging`? Out of scope for this change either way.
