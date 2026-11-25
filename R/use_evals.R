#' Set up the evals
#'
#' Creates `dev/evals.R`, a script that checks, through Claude Code, that the
#' model calls the right tool with the right arguments. Replace its example
#' cases with questions your users ask.
#'
#' @param pkg Path to the package.
#'
#' @export
use_evals <- function(
  pkg = "."
) {
  script <- file.path(
    pkg,
    "dev",
    "evals.R"
  )
  if (
    file.exists(
      script
    )
  ) {
    stop(
      script,
      " already exists."
    )
  }
  file.copy(
    system.file(
      "templates",
      "evals.R",
      package = "mordew"
    ),
    script
  )
}
