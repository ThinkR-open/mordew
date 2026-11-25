test_that("no function can turn an argument into code", {
  expect_identical(
    mordew::check_tools(),
    character()
  )
})
