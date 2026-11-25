# Does the model call the right tool, with the right arguments?
# Run from the root of the package:
#   Rscript dev/evals.R
# Needs the claude CLI, logged in. One Claude Code request per case and
# run. Stops when a case passes in less than 80% of its runs.

cases <- list(
  mordew::eval_case(
    "A question a user would ask",
    mordew::tool_call(
      "name_of_tool",
      argument = "value"
    )
  ),
  mordew::eval_case(
    "A question no tool answers"
  )
)

results <- mordew::run_evals(
  cases,
  runs = 5
)
print(
  results,
  right = FALSE,
  row.names = FALSE
)
mordew::assert_pass_rate(
  results
)
