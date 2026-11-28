test_that("expect_prompt() passes on a prompt that is got", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_success(
    expect_prompt(
      "review_run",
      list(
        run_id = "42"
      ),
      package = "runlog"
    )
  )
})

test_that("expect_prompt() passes on a text that matches", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_success(
    expect_prompt(
      "review_run",
      list(
        run_id = "42"
      ),
      regexp = "run 42",
      package = "runlog"
    )
  )
})

test_that("expect_prompt() fails on a text that does not match", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_failure(
    expect_prompt(
      "review_run",
      list(
        run_id = "42"
      ),
      regexp = "trail",
      package = "runlog"
    ),
    "The text of prompt `review_run` does not match `trail`:\nReview run 42"
  )
})
