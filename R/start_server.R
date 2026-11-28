start_server <- function(
  package,
  path = find.package(
    package
  ),
  timeout = 30
) {
  stdio_client(
    rscript(),
    server_args(
      package,
      path
    ),
    timeout
  )
}

server_args <- function(
  package,
  path
) {
  c(
    "--no-init-file",
    "-e",
    paste0(
      ".libPaths(",
      paste(
        deparse(
          .libPaths()
        ),
        collapse = ""
      ),
      "); ",
      if (
        from_source(
          path
        )
      ) {
        paste0(
          "pkgload::load_all(",
          deparse(
            path
          ),
          ", quiet = TRUE); "
        )
      },
      package,
      "::run_mcp_server()"
    )
  )
}

from_source <- function(
  path
) {
  !dir.exists(
    file.path(
      path,
      "Meta"
    )
  )
}

rscript <- function() {
  file.path(
    R.home(
      "bin"
    ),
    paste0(
      "Rscript",
      if (on_windows()) ".exe"
    )
  )
}

on_windows <- function() {
  .Platform$OS.type == "windows"
}

request_tool <- function(
  client,
  tool,
  args,
  task = FALSE
) {
  params <- named_call(
    tool,
    args
  )
  if (
    !task &&
      !identical(
        tool_task_support(
          client,
          tool
        ),
        "required"
      )
  ) {
    return(
      request_result(
        client,
        "tools/call",
        params
      )
    )
  }
  params$task <- empty_object()
  task <- request_result(
    client,
    "tools/call",
    params
  )$task
  request_result(
    client,
    "tasks/result",
    list(
      taskId = task$taskId
    )
  )
}

tool_task_support <- function(
  client,
  tool
) {
  if (is.null(client$tools)) {
    client$tools <- request_result(
      client,
      "tools/list",
      NULL
    )$tools
  }
  Find(
    function(definition) {
      identical(
        definition$name,
        tool
      )
    },
    client$tools
  )$execution$taskSupport
}

named_call <- function(
  name,
  args
) {
  list(
    name = name,
    arguments = if (length(args) == 0) empty_object() else args
  )
}

request_server <- function(
  package,
  timeout,
  method,
  params
) {
  client <- start_server(
    package,
    timeout = timeout
  )
  on.exit(
    client_stop(
      client
    )
  )
  request_result(
    client,
    method,
    params
  )
}

request_result <- function(
  client,
  method,
  params
) {
  response <- client_request(
    client,
    method,
    params
  )
  if (!is.null(response$error)) {
    stop(
      response$error$message,
      call. = FALSE
    )
  }
  response$result
}
