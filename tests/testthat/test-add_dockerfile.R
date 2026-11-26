test_that("add_dockerfile() writes a Dockerfile that serves the package over HTTP", {
  skip_if_not_installed(
    "dockerfiler"
  )
  path <- local_runlog()

  add_dockerfile(
    path,
    sysreqs = FALSE
  )

  expect_contains(
    readLines(
      file.path(
        path,
        "Dockerfile"
      )
    ),
    c(
      "RUN useradd --create-home mordew",
      "USER mordew",
      "EXPOSE 8080",
      "HEALTHCHECK CMD Rscript -e 'readLines(\"http://127.0.0.1:8080/health\", warn = FALSE)'",
      "CMD [\"Rscript\", \"-e\", \"mordew::run_mcp_server('runlog', transport = 'http', host = '0.0.0.0', port = 8080)\"]"
    )
  )
})

test_that("add_dockerfile() keeps the Dockerfile out of the build", {
  skip_if_not_installed(
    "dockerfiler"
  )
  path <- local_runlog()

  add_dockerfile(
    path,
    sysreqs = FALSE
  )

  expect_contains(
    readLines(
      file.path(
        path,
        ".Rbuildignore"
      )
    ),
    "^Dockerfile$"
  )
})
