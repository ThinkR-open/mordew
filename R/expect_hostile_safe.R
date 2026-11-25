#' Expect a tool to answer extreme arguments
#'
#' Calls the tool through its MCP server with `args`, replacing one argument
#' at a time by each extreme value its schema accepts: an empty or a huge
#' string, the bounds or the largest numbers. Expects an answer, success or
#' `isError`, to every call: not a server that stops or hangs. A success can
#' still leak data, which this does not check.
#'
#' @inheritParams call_tool
#' @param args Named list of valid arguments, the base of every call. Invalid
#'   ones fail the expectation: the server would reject every call before the
#'   tool runs.
#' @param timeout Seconds to wait for each answer of the server.
#'
#' @export
expect_hostile_safe <- function(
  tool,
  args = list(),
  package = testthat::testing_package(),
  timeout = 30
) {
  client <- start_server(
    package
  )
  on.exit(
    client_stop(
      client
    )
  )
  client$timeout <- timeout
  schema <- Find(
    function(listed) {
      identical(
        listed$name,
        tool
      )
    },
    client_request(
      client,
      "tools/list"
    )$result$tools
  )$inputSchema
  problem <- tryCatch(
    {
      validate_arguments(
        args,
        schema
      )
      NULL
    },
    error = conditionMessage
  )
  failure <- if (is.null(problem)) {
    hostile_failure(
      client,
      tool,
      args,
      schema$properties
    )
  } else {
    paste0(
      "The arguments of `",
      tool,
      "` are not valid: ",
      problem
    )
  }
  testthat::expect(
    is.null(
      failure
    ),
    failure
  )
}

hostile_failure <- function(
  client,
  tool,
  args,
  properties
) {
  for (name in names(properties)) {
    for (value in extreme_values(properties[[name]])) {
      call <- args
      call[[name]] <- value
      error <- tryCatch(
        {
          request_tool(
            client,
            tool,
            call
          )
          NULL
        },
        error = conditionMessage
      )
      if (!is.null(error)) {
        return(
          paste0(
            "Tool `",
            tool,
            "` failed with `",
            name,
            "` = ",
            describe_value(
              value
            ),
            ":\n",
            error
          )
        )
      }
    }
  }
}

describe_value <- function(
  value
) {
  if (is.character(value)) {
    return(
      paste(
        "a string of",
        nchar(
          value
        ),
        "characters"
      )
    )
  }
  format(
    value
  )
}
