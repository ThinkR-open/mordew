source(
  "../walkthrough.R"
)

local_project <- function(
  env = parent.frame()
) {
  withr::local_dir(
    withr::local_tempdir(
      .local_envir = env
    ),
    .local_envir = env
  )
  dir.create(
    "R"
  )
}

test_that("walkthrough_out() moves the comments of a file into the doc", {
  local_project()
  writeLines(
    c(
      "f <- function() {",
      "  #~ Says hello.",
      "  print(",
      "    \"hello\"",
      "  )",
      "}"
    ),
    "R/f.R"
  )
  walkthrough_out(
    "R/f.R",
    "walkthrough.md"
  )
  expect_identical(
    readLines(
      "R/f.R"
    ),
    c(
      "f <- function() {",
      "  print(",
      "    \"hello\"",
      "  )",
      "}"
    )
  )
  expect_identical(
    readLines(
      "walkthrough.md"
    ),
    c(
      "# Walkthrough",
      "",
      "## R/f.R",
      "",
      "### `print(` #1",
      "",
      "Says hello."
    )
  )
})

test_that("walkthrough_out() leaves roxygen and ordinary comments in the code", {
  local_project()
  writeLines(
    c(
      "#' Title",
      "f <- function() {",
      "  # Kept.",
      "  #~ Moved.",
      "  1",
      "}"
    ),
    "R/f.R"
  )
  walkthrough_out(
    "R/f.R",
    "walkthrough.md"
  )
  expect_identical(
    readLines(
      "R/f.R"
    ),
    c(
      "#' Title",
      "f <- function() {",
      "  # Kept.",
      "  1",
      "}"
    )
  )
})

test_that("walkthrough_out() numbers a line found several times", {
  local_project()
  writeLines(
    c(
      "#~ First.",
      "print(",
      "  1",
      ")",
      "#~ Second,",
      "#~ on two lines.",
      "print(",
      "  2",
      ")"
    ),
    "R/f.R"
  )
  walkthrough_out(
    "R/f.R",
    "walkthrough.md"
  )
  expect_identical(
    readLines(
      "walkthrough.md"
    ),
    c(
      "# Walkthrough",
      "",
      "## R/f.R",
      "",
      "### `print(` #1",
      "",
      "First.",
      "",
      "### `print(` #2",
      "",
      "Second,",
      "on two lines."
    )
  )
})

test_that("walkthrough_out() replaces only the sections of files with comments", {
  local_project()
  writeLines(
    c(
      "# Walkthrough",
      "",
      "## R/g.R",
      "",
      "### `g()` #1",
      "",
      "Kept.",
      "",
      "## R/f.R",
      "",
      "### `f()` #1",
      "",
      "Old."
    ),
    "walkthrough.md"
  )
  writeLines(
    "g()",
    "R/g.R"
  )
  writeLines(
    c(
      "#~ New.",
      "f()"
    ),
    "R/f.R"
  )
  walkthrough_out(
    c(
      "R/g.R",
      "R/f.R"
    ),
    "walkthrough.md"
  )
  expect_identical(
    readLines(
      "walkthrough.md"
    ),
    c(
      "# Walkthrough",
      "",
      "## R/g.R",
      "",
      "### `g()` #1",
      "",
      "Kept.",
      "",
      "## R/f.R",
      "",
      "### `f()` #1",
      "",
      "New."
    )
  )
})

test_that("walkthrough_out() changes nothing when a comment has no line below", {
  local_project()
  writeLines(
    c(
      "#~ Kept.",
      "f()"
    ),
    "R/f.R"
  )
  writeLines(
    c(
      "g()",
      "#~ No line below."
    ),
    "R/g.R"
  )
  expect_error(
    walkthrough_out(
      c(
        "R/f.R",
        "R/g.R"
      ),
      "walkthrough.md"
    ),
    "R/g.R: the last walkthrough comment has no line below.",
    fixed = TRUE
  )
  expect_identical(
    readLines(
      "R/f.R"
    ),
    c(
      "#~ Kept.",
      "f()"
    )
  )
})

test_that("walkthrough_in() puts the comments back above their line", {
  local_project()
  original <- c(
    "f <- function() {",
    "  #~ First.",
    "  print(",
    "    1",
    "  )",
    "  #~ Second,",
    "  #~ on two lines.",
    "  print(",
    "    2",
    "  )",
    "}"
  )
  writeLines(
    original,
    "R/f.R"
  )
  walkthrough_out(
    "R/f.R",
    "walkthrough.md"
  )
  doc <- readLines(
    "walkthrough.md"
  )
  walkthrough_in(
    "R/f.R",
    "walkthrough.md"
  )
  expect_identical(
    readLines(
      "R/f.R"
    ),
    original
  )
  expect_identical(
    readLines(
      "walkthrough.md"
    ),
    doc
  )
})

test_that("walkthrough_in() leaves files without a section alone", {
  local_project()
  writeLines(
    c(
      "#~ Moved.",
      "f()"
    ),
    "R/f.R"
  )
  writeLines(
    "g()",
    "R/g.R"
  )
  walkthrough_out(
    "R/f.R",
    "walkthrough.md"
  )
  walkthrough_in(
    c(
      "R/f.R",
      "R/g.R"
    ),
    "walkthrough.md"
  )
  expect_identical(
    readLines(
      "R/g.R"
    ),
    "g()"
  )
})

test_that("walkthrough_in() stops when the line of a comment is gone", {
  local_project()
  writeLines(
    c(
      "#~ Moved.",
      "f()"
    ),
    "R/f.R"
  )
  walkthrough_out(
    "R/f.R",
    "walkthrough.md"
  )
  writeLines(
    "g()",
    "R/f.R"
  )
  expect_error(
    walkthrough_in(
      "R/f.R",
      "walkthrough.md"
    ),
    "R/f.R: the line `f()` #1 of a comment is gone.",
    fixed = TRUE
  )
  expect_identical(
    readLines(
      "R/f.R"
    ),
    "g()"
  )
})

test_that("walkthrough_in() stops on a file that already has comments", {
  local_project()
  writeLines(
    c(
      "#~ Moved.",
      "f()"
    ),
    "R/f.R"
  )
  walkthrough_out(
    "R/f.R",
    "walkthrough.md"
  )
  walkthrough_in(
    "R/f.R",
    "walkthrough.md"
  )
  expect_error(
    walkthrough_in(
      "R/f.R",
      "walkthrough.md"
    ),
    "R/f.R already has walkthrough comments: run walkthrough_out() first.",
    fixed = TRUE
  )
})

test_that("walkthrough_files() lists the R files of R/ and of the template", {
  local_project()
  dir.create(
    "inst/mordewexample/dev",
    recursive = TRUE
  )
  file.create(
    c(
      "R/a.R",
      "inst/mordewexample/DESCRIPTION",
      "inst/mordewexample/dev/b.R"
    )
  )
  expect_identical(
    walkthrough_files(),
    c(
      "R/a.R",
      "inst/mordewexample/dev/b.R"
    )
  )
})
