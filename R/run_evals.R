#' Run eval cases
#'
#' Asks Claude Code each question in a session restricted to the package's
#' MCP server, and checks the tool calls of the model against the answers of
#' the case. Needs the `claude` CLI, logged in: each run of a case costs one
#' request. When `ANTHROPIC_API_KEY` is set, as in CI, the session runs with
#' `--bare`: it leaves out the developer's `CLAUDE.md`, memory, hooks and
#' plugins, so that the results do not depend on the machine.
#'
#' @param cases A list of [eval_case()].
#' @param runs Number of times to ask each case: the model does not always
#'   answer the same way.
#' @param pkg Path to the package.
#'
#' @return A data frame with one row per run of a case: `question`, `run`,
#'   `passed`, the tool `calls` of the model, their number `n_calls`, and
#'   `too_many_calls`, `TRUE` when the model made more calls than the longest
#'   answer of the case.
#'
#' @export
run_evals <- function(
  cases,
  runs = 1,
  pkg = "."
) {
  do.call(
    rbind,
    Map(
      eval_run,
      rep(
        cases,
        each = runs
      ),
      seq_len(
        runs
      ),
      MoreArgs = list(
        pkg = pkg
      )
    )
  )
}

eval_run <- function(
  case,
  run,
  pkg
) {
  calls <- claude_tool_calls(
    case$question,
    pkg
  )
  data.frame(
    question = case$question,
    run = run,
    passed = case_passes(
      case$answers,
      calls
    ),
    calls = describe_calls(
      calls
    ),
    n_calls = length(
      calls
    ),
    too_many_calls = length(
      calls
    ) >
      max(
        lengths(
          case$answers
        ),
        0
      )
  )
}

describe_calls <- function(
  calls
) {
  paste(
    vapply(
      calls,
      function(call) {
        paste(
          call$tool,
          jsonlite::toJSON(
            call$args,
            auto_unbox = TRUE
          )
        )
      },
      character(
        1
      )
    ),
    collapse = " + "
  )
}
