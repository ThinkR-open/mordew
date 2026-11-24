test_that("expect_tool_schema() snapshots the definition sent to clients", {
  local_dev_package()

  expect_tool_schema(
    "echo",
    package = "runlog"
  )
})

test_that("expect_tool_schema() refuses an unknown tool", {
  local_dev_package()

  expect_error(
    expect_tool_schema(
      "nope",
      package = "runlog"
    ),
    "`runlog` has no tool named `nope`."
  )
})
