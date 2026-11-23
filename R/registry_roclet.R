#' Roclet generating the tool registry
#'
#' Turns the `@mcpTool` functions of a package into its tool registry.
#' Enable it in the package's `DESCRIPTION` with
#' `Roxygen: list(roclets = c("collate", "namespace", "rd", "mordew::registry_roclet"))`.
#'
#' @export
registry_roclet <- function() {
  roxygen2::roclet(
    "registry"
  )
}

#' @exportS3Method roxygen2::roxy_tag_parse
roxy_tag_parse.roxy_tag_mcpTool <- function(
  x
) {
  x$val <- trimws(
    x$raw
  )
  x
}

#' @exportS3Method roxygen2::roclet_process
roclet_process.roclet_registry <- function(
  x,
  blocks,
  env,
  base_path
) {
  registry <- list()
  for (block in blocks) {
    if (
      roxygen2::block_has_tags(
        block,
        "mcpTool"
      )
    ) {
      entry <- tool_entry(
        block
      )
      if (entry$tool$name %in% names(registry)) {
        stop(
          "Two tools are named `",
          entry$tool$name,
          "`."
        )
      }
      registry[[entry$tool$name]] <- entry
    }
  }
  registry
}

tool_entry <- function(
  block
) {
  fun <- block$object$alias
  name <- roxygen2::block_get_tag_value(
    block,
    "mcpTool"
  )
  if (name == "") {
    name <- fun
  }
  if (
    !grepl(
      "^[A-Za-z0-9_.-]{1,128}$",
      name
    )
  ) {
    stop(
      "`",
      name,
      "` is not a valid tool name: use 1 to 128 characters among A-Z a-z 0-9 _ - ."
    )
  }
  list(
    fun = fun,
    tool = list(
      name = name
    )
  )
}
