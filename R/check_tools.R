#' Check the tools for calls that run code
#'
#' Reads, without running it, the code of every function of the package,
#' tools and the helpers they call, and reports the calls through which an
#' argument of the model could become code: `eval()`, `parse()`, `source()`,
#' `system()` and similar.
#'
#' @param package Package to check, by default the one being tested.
#'
#' @return One line per function and denied call, such as
#'   `"grep_runs() calls system()"`; none when the code is clean.
#'
#' @export
check_tools <- function(
  package = testthat::testing_package()
) {
  namespace <- asNamespace(
    package
  )
  functions <- Filter(
    is.function,
    mget(
      ls(
        namespace,
        all.names = TRUE
      ),
      envir = namespace
    )
  )
  calls <- lapply(
    functions,
    denied_calls
  )
  paste0(
    rep(
      names(
        calls
      ),
      lengths(
        calls
      )
    ),
    "() calls ",
    unlist(
      calls,
      use.names = FALSE
    ),
    "()",
    recycle0 = TRUE
  )
}
