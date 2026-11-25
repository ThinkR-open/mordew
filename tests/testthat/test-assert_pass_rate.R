test_that("assert_pass_rate() returns the results when each case passes often enough", {
  results <- data.frame(
    question = rep(
      c(
        "Quelles sont mes 5 sorties les plus rapides ?",
        "Liste mes compétitions de 2025."
      ),
      each = 5
    ),
    passed = c(
      TRUE,
      TRUE,
      TRUE,
      TRUE,
      FALSE,
      TRUE,
      TRUE,
      TRUE,
      TRUE,
      TRUE
    )
  )

  expect_identical(
    assert_pass_rate(
      results
    ),
    results
  )
})

test_that("assert_pass_rate() stops on a case below the pass rate", {
  results <- data.frame(
    question = rep(
      c(
        "Quelles sont mes 5 sorties les plus rapides ?",
        "Liste mes compétitions de 2025."
      ),
      each = 5
    ),
    passed = c(
      TRUE,
      TRUE,
      FALSE,
      TRUE,
      FALSE,
      TRUE,
      TRUE,
      TRUE,
      TRUE,
      TRUE
    )
  )

  expect_error(
    assert_pass_rate(
      results
    ),
    "Cases below a pass rate of 80%:\nQuelles sont mes 5 sorties les plus rapides ? (60%)",
    fixed = TRUE
  )
})
