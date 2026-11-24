# Does Claude pick the right runlog tool, with the right arguments?
# Measures the current {mordew} through inst/runlog: run dev/example.R
# first, then, from the root of {mordew}:
#   Rscript --no-init-file dev/evals.R [runs]
# Needs the claude CLI, logged in. One Claude Code request per case and
# run; runs defaults to 1.

pkgload::load_all(
  quiet = TRUE
)

lib <- tempfile()
dir.create(
  lib
)
.libPaths(
  c(
    lib,
    .libPaths()
  )
)
utils::install.packages(
  c(
    ".",
    "inst/runlog"
  ),
  repos = NULL,
  type = "source",
  lib = lib,
  quiet = TRUE
)

session <- tempfile()
dir.create(
  session
)
jsonlite::write_json(
  list(
    mcpServers = list(
      runlog = list(
        command = rscript(),
        args = c(
          "--no-init-file",
          "-e",
          paste0(
            ".libPaths(",
            paste(
              deparse(
                .libPaths()
              ),
              collapse = ""
            ),
            "); runlog::run_mcp_server()"
          )
        )
      )
    )
  ),
  file.path(
    session,
    "runlog.json"
  ),
  auto_unbox = TRUE
)

runs <- max(
  1L,
  as.integer(
    commandArgs(
      TRUE
    )[1]
  ),
  na.rm = TRUE
)

tool_call <- function(
  tool,
  ...
) {
  list(
    tool = tool,
    args = list(
      ...
    )
  )
}

partial <- function(
  x
) {
  structure(
    x,
    class = "partial"
  )
}

case <- function(
  question,
  ...
) {
  list(
    question = question,
    answers = lapply(
      list(
        ...
      ),
      function(answer) {
        if (is.null(answer$tool)) answer else list(answer)
      }
    )
  )
}

cases <- list(
  case(
    "Combien de kilomètres ai-je couru en 2024, par type de sortie ?",
    tool_call(
      "summarise_runs",
      year = 2024
    )
  ),
  case(
    "Fais-moi le bilan de mon année 2025.",
    tool_call(
      "summarise_runs",
      year = 2025
    )
  ),
  case(
    "Combien de kilomètres ai-je couru chaque mois en 2025 ?",
    tool_call(
      "summarise_runs_by_month",
      year = 2025
    )
  ),
  case(
    "Quel mois de 2024 ai-je le plus couru ?",
    tool_call(
      "summarise_runs_by_month",
      year = 2024
    )
  ),
  case(
    "Quelles sont mes 5 sorties les plus longues ?",
    tool_call(
      "longest_runs",
      n = 5
    )
  ),
  case(
    "Quelles sont mes 3 plus longues distances en compétition ?",
    tool_call(
      "longest_runs",
      n = 3,
      type = "race"
    )
  ),
  case(
    "Quelles sont mes 5 sorties les plus rapides ?",
    tool_call(
      "fastest_runs",
      n = 5
    )
  ),
  case(
    "Mes 3 séances de fractionné les plus rapides.",
    tool_call(
      "fastest_runs",
      n = 3,
      type = "interval"
    )
  ),
  case(
    "Liste mes compétitions de 2025.",
    tool_call(
      "get_runs",
      year = 2025,
      type = "race"
    )
  ),
  case(
    "Montre-moi toutes mes sorties de 2024.",
    tool_call(
      "get_runs",
      year = 2024
    )
  ),
  case(
    "Show me my long runs in 2024.",
    tool_call(
      "get_runs",
      year = 2024,
      type = "long"
    )
  ),
  case(
    "Quel temps fera-t-il demain à Bruxelles ?"
  )
)

tool_calls <- function(
  question
) {
  run <- processx::run(
    "claude",
    c(
      "-p",
      question,
      "--output-format",
      "stream-json",
      "--verbose",
      claude_args(
        "runlog"
      )
    ),
    wd = session,
    error_on_status = FALSE
  )
  if (run$status != 0) {
    stop(
      "claude failed:\n",
      run$stderr,
      call. = FALSE
    )
  }
  messages <- lapply(
    Filter(
      nzchar,
      strsplit(
        run$stdout,
        "\n"
      )[[1]]
    ),
    jsonlite::fromJSON,
    simplifyVector = FALSE
  )
  blocks <- unlist(
    lapply(
      messages,
      function(message) {
        if (
          identical(
            message$type,
            "assistant"
          )
        ) {
          message$message$content
        }
      }
    ),
    recursive = FALSE
  )
  lapply(
    Filter(
      function(block) {
        identical(
          block$type,
          "tool_use"
        )
      },
      blocks
    ),
    function(block) {
      list(
        tool = sub(
          "^mcp__runlog__",
          "",
          block$name
        ),
        args = block$input
      )
    }
  )
}

arg_matches <- function(
  expected,
  actual
) {
  if (
    inherits(
      expected,
      "partial"
    )
  ) {
    return(
      is.character(
        actual
      ) &&
        nzchar(
          actual
        ) &&
        grepl(
          tolower(
            actual
          ),
          tolower(
            expected
          ),
          fixed = TRUE
        )
    )
  }
  identical(
    as.character(
      expected
    ),
    as.character(
      actual
    )
  )
}

matches <- function(
  expected,
  actual,
  args
) {
  identical(
    expected$tool,
    actual$tool
  ) &&
    (!args ||
      setequal(
        names(
          expected$args
        ),
        names(
          actual$args
        )
      ) &&
        all(
          vapply(
            names(
              expected$args
            ),
            function(name) {
              arg_matches(
                expected$args[[name]],
                actual$args[[name]]
              )
            },
            logical(
              1
            )
          )
        ))
}

passes <- function(
  case,
  calls,
  args
) {
  if (length(case$answers) == 0) {
    return(
      length(
        calls
      ) ==
        0
    )
  }
  any(
    vapply(
      case$answers,
      function(answer) {
        all(
          vapply(
            answer,
            function(expected) {
              any(
                vapply(
                  calls,
                  matches,
                  logical(
                    1
                  ),
                  expected = expected,
                  args = args
                )
              )
            },
            logical(
              1
            )
          )
        )
      },
      logical(
        1
      )
    )
  )
}

as_key <- function(
  args
) {
  if (length(args) == 0) {
    return(
      "{}"
    )
  }
  as.character(
    jsonlite::toJSON(
      lapply(
        args[order(
          names(
            args
          )
        )],
        unclass
      ),
      auto_unbox = TRUE
    )
  )
}

describe <- function(
  calls
) {
  if (length(calls) == 0) {
    return(
      "no call"
    )
  }
  paste(
    vapply(
      calls,
      function(call) {
        paste(
          call$tool,
          as_key(
            call$args
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

results <- do.call(
  rbind,
  lapply(
    seq_along(
      cases
    ),
    function(i) {
      do.call(
        rbind,
        lapply(
          seq_len(
            runs
          ),
          function(run) {
            calls <- tool_calls(
              cases[[i]]$question
            )
            data.frame(
              case = i,
              run = run,
              tool_ok = passes(
                cases[[i]],
                calls,
                FALSE
              ),
              args_ok = passes(
                cases[[i]],
                calls,
                TRUE
              ),
              called = describe(
                calls
              )
            )
          }
        )
      )
    }
  )
)

print(
  results,
  right = FALSE,
  row.names = FALSE
)
cat(
  "\nRight tool:",
  sum(
    results$tool_ok
  ),
  "/",
  nrow(
    results
  ),
  "\nRight arguments:",
  sum(
    results$args_ok
  ),
  "/",
  nrow(
    results
  ),
  "\n"
)
for (i in which(
  !results$args_ok
)) {
  case <- cases[[results$case[i]]]
  cat(
    "\n",
    case$question,
    "\n  expected:",
    if (length(case$answers) == 0) {
      "no call"
    } else {
      paste(
        vapply(
          case$answers,
          describe,
          character(
            1
          )
        ),
        collapse = " or "
      )
    },
    "\n  called:  ",
    results$called[i],
    "\n"
  )
}
