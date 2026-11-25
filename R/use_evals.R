#' Set up the evals
#'
#' Creates `dev/evals.R`, a script that checks, through Claude Code, that the
#' model calls the right tool with the right arguments, and
#' `.github/workflows/evals.yaml`, a workflow that runs it when started by
#' hand. Replace the example cases of the script with questions your users
#' ask, and add an `ANTHROPIC_API_KEY` secret to the repository for the
#' workflow.
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
  workflows <- file.path(
    pkg,
    ".github",
    "workflows"
  )
  dir.create(
    workflows,
    recursive = TRUE,
    showWarnings = FALSE
  )
  file.copy(
    system.file(
      "templates",
      c(
        "evals.R",
        "evals.yaml"
      ),
      package = "mordew"
    ),
    c(
      script,
      file.path(
        workflows,
        "evals.yaml"
      )
    )
  )
}
