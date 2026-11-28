#' Title of the prompt
#'
#' What the prompt asks the model, so that users know when to pick it.
#'
#' @mcpPrompt
#' @export
mordewprompt <- function() {
  readLines(
    system.file(
      "mordew",
      "prompts",
      "mordewprompt.md",
      package = "mordewexample"
    )
  )
}
