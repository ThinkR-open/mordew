test_that("expect_tool_error() passes on an error result that matches", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_success(
    expect_tool_error(
      "echo",
      regexp = "Missing argument `text`",
      package = "runlog"
    )
  )
})

test_that("expect_tool_error() fails on a successful result", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_failure(
    expect_tool_error(
      "echo",
      list(
        text = "trail"
      ),
      package = "runlog"
    ),
    "Tool `echo` did not return an error."
  )
})

test_that("expect_tool_error() fails on an error that does not match", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_failure(
    expect_tool_error(
      "fail_always",
      regexp = "Rain",
      package = "runlog"
    ),
    "The error of tool `fail_always` does not match `Rain`:\nNo runs today."
  )
})
