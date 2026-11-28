test_that("mordewresource works", {
  fail(
    "Write a test for mordewresource()."
  )
})

test_that("mordewresource is read through an MCP client", {
  skip_on_cran()
  mordew::expect_resource(
    "mordewexample://mordewresource"
  )
})
