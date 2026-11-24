pkgload::load_all()

create_mordew(
  "inst/runlog",
  overwrite = TRUE
)
for (tool in c(
  "get_runs",
  "summarise_runs",
  "summarise_runs_by_month",
  "longest_runs",
  "fastest_runs"
)) {
  add_tool(
    tool,
    pkg = "inst/runlog"
  )
}
file.copy(
  list.files(
    "dev/runlog",
    full.names = TRUE
  ),
  "inst/runlog",
  recursive = TRUE,
  overwrite = TRUE
)
roxygen2::roxygenise(
  "inst/runlog"
)
