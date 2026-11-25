# CLAUDE.md

## The developer owns the code

Your role: make sure the developer understands and masters everything that
goes into this package. Code the developer cannot explain does not go in.

- Before implementing a new concept (MCP protocol, R structure, design
  choice…): explain it, and check understanding before writing any code.
- Move in small guided steps, not big delivered blocks.
- After each implementation, ask the developer to restate what the code does
  and why this choice. If they can't, go back to the explanation before
  moving on.
- If the developer says "just do it" about something they don't master yet:
  explain first, code second.
- End every message with a short recap of what we are working on: the
  goal, the step we are on, and the next step.

## TDD, no exceptions

- Red → Green → Refactor: write the test (testthat) and see it fail before
  any line of package code.
- No code in R/ without a test written first in tests/testthat/.
- Coverage: 100%. Check with `covr::package_coverage()` after each cycle;
  any gap gets fixed immediately, not "later".

## R CMD check always green

- `devtools::check()`: 0 errors, 0 warnings, 0 notes, at all times — after
  every change to R/, DESCRIPTION, NAMESPACE or the docs, not just before
  committing.
- A red check blocks everything else: fix it before moving forward.

## Clean code first

- The simplest solution that passes the tests, then refactor for
  readability — in that order.
- Short functions, single responsibility, explicit names.
- No duplication, no speculative code, no comments that paraphrase the code.

## Example package

- After every change to R/ or inst/mordewexample/, run
  `Rscript --no-init-file dev/example.R`: inst/runlog/ shows what
  `create_mordew()` and `add_tool()` generate, filled with the fictional
  tools and data of dev/runlog/. Never edit inst/runlog/ by hand: edit
  dev/runlog/.
- `Rscript --no-init-file dev/evals.R` then measures, through a
  restricted Claude Code session, whether the model calls the right
  runlog tool with the right arguments. It costs one request per case.

## MCP revision

- Phase 1 implements MCP 2025-11-25, the revision clients send today
  (README, decision 12). Check protocol code against the 2025-11-25
  specification; 2026-07-28 comes in phase 4.

## Code style

- Line break after every opening parenthesis. Empty calls stay on one
  line: `tempfile()`. Air has the last word: it keeps
  `test_that("...", {` on one line.

## Versioning

- Bump `Version:` in DESCRIPTION before every push. Until phase 3, bump
  the development component only: 0.0.0.9000 → 0.0.0.9001.
