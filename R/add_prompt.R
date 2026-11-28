#' Add a prompt
#'
#' Creates the prompt file, the text of the prompt in
#' `inst/mordew/prompts/<name>.md`, which the prompt reads, and its test
#' file, from templates.
#'
#' @param name Name of the prompt.
#' @param pkg Path to the package.
#'
#' @export
add_prompt <- function(
  name,
  pkg = "."
) {
  prompt <- function_file(
    name,
    pkg,
    "prompt"
  )
  package <- package_name(
    pkg
  )
  fill_names(
    "prompt.R",
    prompt,
    "mordewprompt",
    name,
    package
  )
  fill_names(
    "prompt.md",
    file.path(
      pkg,
      "inst",
      "mordew",
      "prompts",
      paste0(
        name,
        ".md"
      )
    ),
    "mordewprompt",
    name,
    package
  )
  fill_names(
    "test-prompt.R",
    file.path(
      pkg,
      "tests",
      "testthat",
      paste0(
        "test-prompt_",
        name,
        ".R"
      )
    ),
    "mordewprompt",
    name,
    package
  )
}
