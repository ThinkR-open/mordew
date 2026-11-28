# Walkthrough

## R/create_mordew.R

### `if (` #1

Checked before anything touches the disk: an invalid name deletes
nothing.

### `unlink(` #1

`unlink()` ignores a missing path, hence no `tryCatch()`. With
`overwrite = TRUE`, the old content is lost, not merged.

### `template <- system.file(` #1

The installed {mordew}, where `inst/` is gone:
`<library>/mordew/mordewexample`. Under `load_all()`, the sources'
`inst/mordewexample/`.

### `file.copy(` #1

The content of the template, not the folder itself.

### `file.rename(` #1

A hidden file in `inst/` is an R CMD check NOTE, and `list.files()`
would not copy it anyway.

### `files <- list.files(` #1

Content only, never file names. Hidden files are skipped:
`.Rbuildignore` is not filled.

## inst/mordewexample/R/run.R

### `mordew::run_mcp_server(` #1

The name, written here by `create_mordew()`, not the namespace: over
HTTP, the workers are other R processes that load the package by name.

## inst/mordewexample/tests/testthat/test-check_tools.R

### `expect_identical(` #1

`check_tools()` never throws: comparing with `character()` fails the
test and prints the calls found. No package name: it defaults to the
package under test.
