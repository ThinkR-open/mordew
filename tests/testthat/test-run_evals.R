test_that("run_evals() reports each case with the calls of the model", {
  skip_on_os(
    "windows"
  )
  local_fake_claude(
    withr::local_tempdir()
  )

  expect_identical(
    run_evals(
      list(
        eval_case(
          "Mes 3 séances de fractionné les plus rapides.",
          tool_call(
            "fastest_runs",
            n = 3,
            type = "interval"
          )
        )
      ),
      pkg = local_runlog()
    ),
    data.frame(
      question = "Mes 3 séances de fractionné les plus rapides.",
      run = 1L,
      passed = TRUE,
      calls = 'fastest_runs {"n":3,"type":"interval"}',
      n_calls = 1L,
      too_many_calls = FALSE
    )
  )
})

test_that("run_evals() reports a case the model fails", {
  skip_on_os(
    "windows"
  )
  local_fake_claude(
    withr::local_tempdir()
  )

  expect_false(
    run_evals(
      list(
        eval_case(
          "Quelles sont mes 3 plus longues distances en compétition ?",
          tool_call(
            "longest_runs",
            n = 3,
            type = "race"
          )
        )
      ),
      pkg = local_runlog()
    )$passed
  )
})

test_that("run_evals() asks each case several times", {
  skip_on_os(
    "windows"
  )
  local_fake_claude(
    withr::local_tempdir()
  )

  results <- run_evals(
    list(
      eval_case(
        "Mes 3 séances de fractionné les plus rapides.",
        tool_call(
          "fastest_runs",
          n = 3,
          type = "interval"
        )
      ),
      eval_case(
        "Quel temps fera-t-il demain à Bruxelles ?"
      )
    ),
    runs = 2,
    pkg = local_runlog()
  )

  expect_identical(
    results$question,
    rep(
      c(
        "Mes 3 séances de fractionné les plus rapides.",
        "Quel temps fera-t-il demain à Bruxelles ?"
      ),
      each = 2
    )
  )
  expect_identical(
    results$run,
    c(
      1L,
      2L,
      1L,
      2L
    )
  )
})

test_that("run_evals() flags more calls than the longest answer", {
  skip_on_os(
    "windows"
  )
  local_fake_claude(
    withr::local_tempdir()
  )

  expect_true(
    run_evals(
      list(
        eval_case(
          "Quel temps fera-t-il demain à Bruxelles ?"
        )
      ),
      pkg = local_runlog()
    )$too_many_calls
  )
})
