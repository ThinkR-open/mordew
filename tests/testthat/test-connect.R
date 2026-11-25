test_that("add_connect() declares mordew as the engine and keeps the file out of the build", {
  path <- local_runlog()

  add_connect(
    path
  )

  expect_identical(
    readLines(
      file.path(
        path,
        "_server.yml"
      )
    ),
    "engine: mordew"
  )
  expect_contains(
    readLines(
      file.path(
        path,
        ".Rbuildignore"
      )
    ),
    "^_server\\.yml$"
  )
})

test_that("launch_server() refuses another engine", {
  settings <- withr::local_tempfile(
    lines = "engine: plumber2"
  )

  expect_error(
    launch_server(
      settings
    ),
    "must start with `engine: mordew`"
  )
})

test_that("launch_server() installs the package next to the settings and serves it", {
  skip_if_not_installed(
    "processx"
  )
  withr::local_libpaths(
    .libPaths()
  )
  local_mordew_lib()
  path <- local_tool_package()
  add_connect(
    path
  )
  local_mocked_bindings(
    serve_http = function(
      host,
      port,
      package,
      workers,
      timeout,
      queue,
      token
    ) {
      list(
        host = host,
        port = port,
        package = package,
        token = token
      )
    }
  )

  served <- launch_server(
    file.path(
      path,
      "_server.yml"
    ),
    host = "0.0.0.0",
    port = 3939
  )

  expect_identical(
    served,
    list(
      host = "0.0.0.0",
      port = 3939,
      package = "runlog",
      token = NULL
    )
  )
  expect_false(
    from_source(
      find.package(
        "runlog"
      )
    )
  )
  expect_identical(
    launch_server(
      file.path(
        path,
        "_server.yml"
      )
    )[c(
      "host",
      "port"
    )],
    list(
      host = "127.0.0.1",
      port = 8000
    )
  )
})
