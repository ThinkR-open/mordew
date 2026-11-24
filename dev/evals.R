# Does Claude pick the right runlog tool, with the right arguments?
# Measures the current {mordew} through inst/runlog: run dev/example.R
# first, then, from the root of {mordew}:
#   Rscript --no-init-file dev/evals.R
# Needs the claude CLI, logged in. One Claude Code request per case.

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

case <- function(
  question,
  tool = NA_character_,
  ...
) {
  list(
    question = question,
    tool = tool,
    args = list(
      ...
    )
  )
}

cases <- list(
  case(
    "Combien de kilomètres ai-je couru en 2024, par type de sortie ?",
    "summarise_runs",
    year = 2024
  ),
  case(
    "Fais-moi le bilan de mon année 2025.",
    "summarise_runs",
    year = 2025
  ),
  case(
    "Combien de kilomètres ai-je couru chaque mois en 2025 ?",
    "summarise_runs_by_month",
    year = 2025
  ),
  case(
    "Quel mois de 2024 ai-je le plus couru ?",
    "summarise_runs_by_month",
    year = 2024
  ),
  case(
    "Quelles sont mes 5 sorties les plus longues ?",
    "longest_runs",
    n = 5
  ),
  case(
    "Quelles sont mes 3 plus longues distances en compétition ?",
    "longest_runs",
    n = 3,
    type = "race"
  ),
  case(
    "Quelles sont mes 5 sorties les plus rapides ?",
    "fastest_runs",
    n = 5
  ),
  case(
    "Mes 3 séances de fractionné les plus rapides.",
    "fastest_runs",
    n = 3,
    type = "interval"
  ),
  case(
    "Liste mes compétitions de 2025.",
    "get_runs",
    year = 2025,
    type = "race"
  ),
  case(
    "Montre-moi toutes mes sorties de 2024.",
    "get_runs",
    year = 2024
  ),
  case(
    "Show me my long runs in 2024.",
    "get_runs",
    year = 2024,
    type = "long"
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
  Filter(
    function(block) {
      identical(
        block$type,
        "tool_use"
      )
    },
    blocks
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
      args[order(
        names(
          args
        )
      )],
      auto_unbox = TRUE
    )
  )
}

results <- do.call(
  rbind,
  lapply(
    cases,
    function(case) {
      calls <- tool_calls(
        case$question
      )
      tool <- NA_character_
      args <- list()
      if (length(calls) > 0) {
        tool <- sub(
          "^mcp__runlog__",
          "",
          calls[[1]]$name
        )
        args <- calls[[1]]$input
      }
      tool_ok <- identical(
        tool,
        case$tool
      )
      data.frame(
        question = case$question,
        expected = paste(
          case$tool,
          as_key(
            case$args
          )
        ),
        called = paste(
          tool,
          as_key(
            args
          )
        ),
        calls = length(
          calls
        ),
        tool_ok = tool_ok,
        args_ok = tool_ok &&
          as_key(
            args
          ) ==
            as_key(
              case$args
            )
      )
    }
  )
)

print(
  results[, -1],
  right = FALSE
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
misses <- results[!results$args_ok, ]
for (i in seq_len(
  nrow(
    misses
  )
)) {
  cat(
    "\n",
    misses$question[i],
    "\n  expected:",
    misses$expected[i],
    "\n  called:  ",
    misses$called[i],
    "\n"
  )
}
