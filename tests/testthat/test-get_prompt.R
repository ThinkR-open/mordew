test_that("get_prompt() gets a prompt of the package over stdio", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_identical(
    get_prompt(
      "review_run",
      list(
        run_id = "42"
      ),
      package = "runlog"
    ),
    list(
      messages = list(
        list(
          role = "user",
          content = list(
            type = "text",
            text = "Review run 42"
          )
        )
      )
    )
  )
})

test_that("get_prompt() fails on a protocol error", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_error(
    get_prompt(
      "nope",
      package = "runlog"
    ),
    "Unknown prompt: nope",
    fixed = TRUE
  )
})
