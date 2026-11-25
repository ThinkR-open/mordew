test_that("denied_calls() finds a shell call", {
  expect_identical(
    denied_calls(
      function(pattern, file) {
        system(
          paste(
            "grep",
            pattern,
            file
          )
        )
      }
    ),
    "system"
  )
})

test_that("denied_calls() finds calls nested in other calls", {
  expect_identical(
    denied_calls(
      function(filter) {
        subset(
          runs,
          eval(
            parse(
              text = filter
            )
          )
        )
      }
    ),
    c(
      "eval",
      "parse"
    )
  )
})

test_that("denied_calls() finds a call with its namespace", {
  expect_identical(
    denied_calls(
      function(text) {
        base::system2(
          "echo",
          text
        )
      }
    ),
    "system2"
  )
})

test_that("denied_calls() finds nothing in safe code", {
  expect_identical(
    denied_calls(
      function(runs, n) {
        head(
          runs[
            order(
              -runs$distance_km
            ),
          ],
          n
        )
      }
    ),
    character()
  )
})
