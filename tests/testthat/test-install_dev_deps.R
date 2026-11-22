test_that("install_dev_deps() installs only the missing packages", {
  installed <- NULL
  local_mocked_bindings(
    install.packages = function(
      pkgs,
      ...
    ) {
      installed <<- pkgs
    },
    .package = "utils"
  )

  install_dev_deps(
    c(
      "testthat",
      "notapkgxyz"
    )
  )

  expect_equal(
    installed,
    "notapkgxyz"
  )
})

test_that("install_dev_deps() defaults to the Suggests of mordew", {
  installed <- NULL
  local_mocked_bindings(
    install.packages = function(
      pkgs,
      ...
    ) {
      installed <<- pkgs
    },
    .package = "utils"
  )
  local_mocked_bindings(
    suggested_packages = function() "notapkgxyz"
  )

  install_dev_deps()

  expect_equal(
    installed,
    "notapkgxyz"
  )
})

test_that("suggested_packages() lists the Suggests without versions", {
  expect_contains(
    suggested_packages(),
    "testthat"
  )
})
