test_that("read_resource() reads a resource of the package over stdio", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_identical(
    read_resource(
      "runlog://surfaces",
      package = "runlog"
    ),
    list(
      contents = list(
        list(
          uri = "runlog://surfaces",
          mimeType = "text/plain",
          text = "road, trail, track"
        )
      )
    )
  )
})

test_that("read_resource() fails on a protocol error", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_error(
    read_resource(
      "runlog://shoes",
      package = "runlog"
    ),
    "Resource not found: runlog://shoes",
    fixed = TRUE
  )
})
