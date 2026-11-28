test_that("mordewprompt works", {
  fail(
    "Write a test for mordewprompt()."
  )
})

test_that("mordewprompt is got through an MCP client", {
  skip_on_cran()
  mordew::expect_prompt(
    "mordewprompt"
  )
})
