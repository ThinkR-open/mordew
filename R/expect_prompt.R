#' Expect a prompt to be got through an MCP client
#'
#' Gets the prompt with [get_prompt()], and expects its text to match
#' `regexp`. A prompt that cannot be got, an unknown name, invalid
#' arguments or a function that fails, is an error.
#'
#' @inheritParams get_prompt
#' @param regexp Regular expression the text of the prompt must match, or
#'   `NULL`.
#' @param ... Passed to [get_prompt()].
#'
#' @return The result of `prompts/get`, invisibly.
#'
#' @export
expect_prompt <- function(
  prompt,
  args = list(),
  regexp = NULL,
  ...
) {
  result <- get_prompt(
    prompt,
    args,
    ...
  )
  expect_text(
    result$messages[[1]]$content$text,
    regexp,
    paste0(
      "prompt `",
      prompt,
      "`"
    )
  )
  invisible(
    result
  )
}
