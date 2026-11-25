#' Add a Dockerfile
#'
#' Writes a Dockerfile that installs the package with
#' `dockerfiler::dock_from_desc()`, then serves it over HTTP with its worker
#' pool, as a non-root user, on `0.0.0.0`, probed on `/health`. Give it a
#' token, `docker run -e MORDEW_TOKEN=... -p 8080:8080 <image>`, unless a
#' proxy in front authenticates the clients: without one, it warns at
#' start-up.
#'
#' @param pkg Path to the package.
#' @param port Port the server listens on in the container.
#' @param ... Passed to `dockerfiler::dock_from_desc()`.
#'
#' @export
add_dockerfile <- function(
  pkg = ".",
  port = 8080,
  ...
) {
  dockerfile <- dockerfiler::dock_from_desc(
    file.path(
      pkg,
      "DESCRIPTION"
    ),
    ...
  )
  dockerfile$RUN(
    "useradd --create-home mordew"
  )
  dockerfile$USER(
    "mordew"
  )
  dockerfile$EXPOSE(
    port
  )
  dockerfile$HEALTHCHECK(
    paste0(
      "CMD Rscript -e 'readLines(\"http://127.0.0.1:",
      port,
      "/health\", warn = FALSE)'"
    )
  )
  dockerfile$CMD(
    paste0(
      "[\"Rscript\", \"-e\", \"",
      package_name(
        pkg
      ),
      "::run_mcp_server(transport = 'http', host = '0.0.0.0', port = ",
      port,
      ")\"]"
    )
  )
  dockerfile$write(
    file.path(
      pkg,
      "Dockerfile"
    )
  )
}
