# Does Claude pick the right runlog tool, with the right arguments?
# Measures the current {mordew} through inst/runlog: run dev/example.R
# first, then, from the root of {mordew}:
#   Rscript --no-init-file dev/evals.R [runs]
# Needs the claude CLI, logged in. One Claude Code request per case and
# run; runs defaults to 1.

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
  ".",
  repos = NULL,
  type = "source",
  lib = lib,
  quiet = TRUE
)
pkgload::load_all(
  quiet = TRUE
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

cases <- list(
  eval_case(
    "Combien de kilomètres ai-je couru en 2024, par type de sortie ?",
    tool_call(
      "summarise_runs",
      year = 2024
    )
  ),
  eval_case(
    "Fais-moi le bilan de mon année 2025.",
    tool_call(
      "summarise_runs",
      year = 2025
    )
  ),
  eval_case(
    "Combien de kilomètres ai-je couru chaque mois en 2025 ?",
    tool_call(
      "summarise_runs_by_month",
      year = 2025
    )
  ),
  eval_case(
    "Quel mois de 2024 ai-je le plus couru ?",
    tool_call(
      "summarise_runs_by_month",
      year = 2024
    )
  ),
  eval_case(
    "Quelles sont mes 5 sorties les plus longues ?",
    tool_call(
      "longest_runs",
      n = 5
    )
  ),
  eval_case(
    "Quelles sont mes 3 plus longues distances en compétition ?",
    tool_call(
      "longest_runs",
      n = 3,
      type = "race"
    )
  ),
  eval_case(
    "Quelles sont mes 5 sorties les plus rapides ?",
    tool_call(
      "fastest_runs",
      n = 5
    )
  ),
  eval_case(
    "Mes 3 séances de fractionné les plus rapides.",
    tool_call(
      "fastest_runs",
      n = 3,
      type = "interval"
    )
  ),
  eval_case(
    "Liste mes compétitions de 2025.",
    tool_call(
      "get_runs",
      year = 2025,
      type = "race"
    )
  ),
  eval_case(
    "Montre-moi toutes mes sorties de 2024.",
    tool_call(
      "get_runs",
      year = 2024
    )
  ),
  eval_case(
    "Show me my long runs in 2024.",
    tool_call(
      "get_runs",
      year = 2024,
      type = "long"
    )
  ),
  eval_case(
    "Quel temps fera-t-il demain à Bruxelles ?"
  )
)

results <- run_evals(
  cases,
  runs,
  "inst/runlog"
)
print(
  results,
  right = FALSE,
  row.names = FALSE
)
cat(
  "\nPassed:",
  sum(
    results$passed
  ),
  "/",
  nrow(
    results
  ),
  "\n"
)
