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
  `create_mordew()` generates. Never edit inst/runlog/ by hand.

## Code style

- Line break after every opening parenthesis. Empty calls stay on one
  line: `tempfile()`. Air has the last word: it keeps
  `test_that("...", {` on one line.
