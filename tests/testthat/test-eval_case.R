test_that("eval_case() turns each call into an answer", {
  expect_identical(
    eval_case(
      "Quelles sont mes 5 sorties les plus rapides ?",
      tool_call(
        "fastest_runs",
        n = 5
      )
    ),
    list(
      question = "Quelles sont mes 5 sorties les plus rapides ?",
      answers = list(
        list(
          tool_call(
            "fastest_runs",
            n = 5
          )
        )
      )
    )
  )
})

test_that("eval_case() without a call expects no answer", {
  expect_identical(
    eval_case(
      "Quel temps fera-t-il demain à Bruxelles ?"
    )$answers,
    list()
  )
})

test_that("eval_case() keeps a list of calls as one answer", {
  expect_identical(
    eval_case(
      "Ai-je plus couru en 2025 qu'en 2024 ?",
      list(
        tool_call(
          "summarise_runs",
          year = 2024
        ),
        tool_call(
          "summarise_runs",
          year = 2025
        )
      )
    )$answers,
    list(
      list(
        tool_call(
          "summarise_runs",
          year = 2024
        ),
        tool_call(
          "summarise_runs",
          year = 2025
        )
      )
    )
  )
})
