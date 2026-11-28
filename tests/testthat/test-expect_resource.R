test_that("expect_resource() passes on a resource that is read", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_success(
    expect_resource(
      "runlog://surfaces",
      package = "runlog"
    )
  )
})

test_that("expect_resource() passes on a text that matches", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_success(
    expect_resource(
      "runlog://surfaces",
      regexp = "trail",
      package = "runlog"
    )
  )
})

test_that("expect_resource() fails on a text that does not match", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_failure(
    expect_resource(
      "runlog://surfaces",
      regexp = "mud",
      package = "runlog"
    ),
    "The text of resource `runlog://surfaces` does not match `mud`:\nroad, trail, track"
  )
})
