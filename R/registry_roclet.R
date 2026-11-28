#' Roclet generating the tool registry
#'
#' Turns the `@mcpTool` functions of a package into its tool registry,
#' `mordew_registry`, and its `@mcpResource` functions into
#' `mordew_resources`.
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

#' @exportS3Method roxygen2::roxy_tag_parse
roxy_tag_parse.roxy_tag_mcpResource <- function(
  x
) {
  roxygen2::tag_value(
    x
  )
}

#' @exportS3Method roxygen2::roxy_tag_parse
roxy_tag_parse.roxy_tag_mcpReturns <- function(
  x
) {
  roxygen2::tag_name(
    x
  )
}

parse_toggle <- function(
  x
) {
  roxygen2::tag_toggle(
    x
  )
}

#' @exportS3Method roxygen2::roxy_tag_parse
roxy_tag_parse.roxy_tag_mcpReadOnly <- parse_toggle

#' @exportS3Method roxygen2::roxy_tag_parse
roxy_tag_parse.roxy_tag_mcpNonDestructive <- parse_toggle

#' @exportS3Method roxygen2::roxy_tag_parse
roxy_tag_parse.roxy_tag_mcpIdempotent <- parse_toggle

#' @exportS3Method roxygen2::roxy_tag_parse
roxy_tag_parse.roxy_tag_mcpClosedWorld <- parse_toggle

#' @exportS3Method roxygen2::roxy_tag_parse
roxy_tag_parse.roxy_tag_mcpLimit <- function(
  x
) {
  roxygen2::tag_words(
    x
  )
}

#' @exportS3Method roxygen2::roxy_tag_parse
roxy_tag_parse.roxy_tag_mcpType <- function(
  x
) {
  roxygen2::tag_two_part(
    x,
    "a parameter",
    "a type",
    markdown = FALSE
  )
}

#' @exportS3Method roxygen2::roclet_process
roclet_process.roclet_registry <- function(
  x,
  blocks,
  env,
  base_path
) {
  registry <- list()
  resources <- list()
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
      registry <- add_entry(
        registry,
        entry$tool$name,
        entry,
        "Two tools are named"
      )
    }
    if (
      roxygen2::block_has_tags(
        block,
        "mcpResource"
      )
    ) {
      entry <- resource_entry(
        block
      )
      resources <- add_entry(
        resources,
        entry$resource$uri,
        entry,
        "Two resources have the URI"
      )
    }
  }
  list(
    tools = registry,
    resources = resources
  )
}

add_entry <- function(
  entries,
  key,
  entry,
  duplicate
) {
  if (key %in% names(entries)) {
    stop(
      duplicate,
      " `",
      key,
      "`."
    )
  }
  entries[[key]] <- entry
  entries
}

resource_entry <- function(
  block
) {
  fun <- block_fun(
    block,
    "resource"
  )
  returns <- roxygen2::block_get_tag_value(
    block,
    "mcpReturns"
  )
  if (is.null(returns)) {
    returns <- "text"
  }
  check_returns(
    returns,
    fun
  )
  list(
    fun = fun,
    resource = list(
      uri = roxygen2::block_get_tag_value(
        block,
        "mcpResource"
      ),
      name = fun,
      title = required_tag(
        block,
        fun,
        "title",
        "clients show it to users."
      ),
      description = required_tag(
        block,
        fun,
        "description",
        "clients use it to tell the model what the resource holds."
      ),
      mimeType = c(
        text = "text/plain",
        table = "text/markdown",
        image = "image/png",
        json = "application/json"
      )[[returns]]
    ),
    returns = returns
  )
}

check_returns <- function(
  returns,
  fun
) {
  if (
    !isTRUE(
      returns %in%
        c(
          "text",
          "table",
          "image",
          "json"
        )
    )
  ) {
    stop(
      "`",
      fun,
      "` needs `@mcpReturns` text, table, image or json."
    )
  }
}

required_tag <- function(
  block,
  fun,
  tag,
  reason
) {
  value <- roxygen2::block_get_tag(
    block,
    tag
  )$raw
  if (is.null(value)) {
    stop(
      "`",
      fun,
      "` has no ",
      tag,
      ": ",
      reason
    )
  }
  value
}

block_fun <- function(
  block,
  kind
) {
  fun <- block$object$alias
  if (
    !is.function(
      block$object$value
    )
  ) {
    stop(
      "`",
      fun,
      "` is not a function: only a function can be a ",
      kind,
      "."
    )
  }
  fun
}

tool_entry <- function(
  block
) {
  fun <- block_fun(
    block,
    "tool"
  )
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
  title <- required_tag(
    block,
    fun,
    "title",
    "clients show it to users."
  )
  description <- required_tag(
    block,
    fun,
    "description",
    "the model reads it to choose the tool."
  )
  returns <- roxygen2::block_get_tag_value(
    block,
    "mcpReturns"
  )
  check_returns(
    returns,
    fun
  )
  tool <- list(
    name = name,
    title = title,
    description = description,
    inputSchema = tool_input_schema(
      block,
      fun
    )
  )
  tool$annotations <- tool_annotations(
    block
  )
  entry <- list(
    fun = fun,
    tool = tool,
    returns = returns
  )
  entry$limit <- tool_limit(
    block,
    fun,
    returns
  )
  entry
}

tool_limit <- function(
  block,
  fun,
  returns
) {
  words <- roxygen2::block_get_tag_value(
    block,
    "mcpLimit"
  )
  if (is.null(words)) {
    return(
      NULL
    )
  }
  if (
    length(words) != 2 ||
      words[[1]] != "rows" ||
      !grepl(
        "^[1-9][0-9]*$",
        words[[2]]
      )
  ) {
    stop(
      "`",
      fun,
      "` needs `@mcpLimit rows <n>`, with n a positive integer."
    )
  }
  if (returns != "table") {
    stop(
      "`",
      fun,
      "` returns ",
      returns,
      ": `@mcpLimit rows` needs `@mcpReturns table`."
    )
  }
  list(
    rows = as.integer(
      words[[2]]
    )
  )
}

tool_input_schema <- function(
  block,
  fun
) {
  params <- formals(
    block$object$value
  )
  types <- list()
  for (tag in roxygen2::block_get_tags(
    block,
    "mcpType"
  )) {
    if (!tag$val$name %in% names(params)) {
      stop(
        "`",
        fun,
        "`: `@mcpType ",
        tag$val$name,
        "` names no parameter."
      )
    }
    types[[tag$val$name]] <- param_type(
      tag,
      block,
      fun
    )
  }
  no_default <- vapply(
    params,
    identical,
    logical(1),
    quote(
      expr =
    )
  )
  for (param in names(params)) {
    if (is.null(types[[param]])) {
      stop(
        "`",
        fun,
        "`: parameter `",
        param,
        "` has no `@mcpType`."
      )
    }
    if (types[[param]]$required != no_default[[param]]) {
      stop(
        "`",
        fun,
        "`: parameter `",
        param,
        "` needs `required = FALSE` if and only if it has a default value."
      )
    }
  }
  do.call(
    type_object,
    types[names(params)]
  )$schema
}

param_type <- function(
  tag,
  block,
  fun
) {
  type <- eval(
    str2lang(
      tag$val$description
    ),
    topenv()
  )
  if (
    !identical(
      names(type),
      c(
        "schema",
        "required"
      )
    )
  ) {
    stop(
      "`",
      fun,
      "`: `@mcpType ",
      tag$val$name,
      "` is not a mordew type."
    )
  }
  type$schema$description <- param_description(
    block,
    fun,
    tag$val$name
  )
  type
}

param_description <- function(
  block,
  fun,
  param
) {
  for (tag in roxygen2::block_get_tags(
    block,
    "param"
  )) {
    if (tag$val$name == param) {
      return(
        trimws(
          sub(
            "^\\S+\\s+",
            "",
            tag$raw
          )
        )
      )
    }
  }
  stop(
    "`",
    fun,
    "`: parameter `",
    param,
    "` has no `@param`."
  )
}

tool_annotations <- function(
  block
) {
  hints <- list(
    mcpReadOnly = list(
      readOnlyHint = TRUE
    ),
    mcpNonDestructive = list(
      destructiveHint = FALSE
    ),
    mcpIdempotent = list(
      idempotentHint = TRUE
    ),
    mcpClosedWorld = list(
      openWorldHint = FALSE
    )
  )
  unlist(
    unname(
      hints[
        vapply(
          names(hints),
          roxygen2::block_has_tags,
          logical(1),
          block = block
        )
      ]
    ),
    recursive = FALSE
  )
}

#' @exportS3Method roxygen2::roclet_output
roclet_output.roclet_registry <- function(
  x,
  results,
  base_path,
  ...
) {
  writeLines(
    c(
      "# Generated by mordew: do not edit by hand.",
      "",
      assignment(
        "mordew_registry",
        results$tools
      ),
      "",
      assignment(
        "mordew_resources",
        results$resources
      )
    ),
    file.path(
      base_path,
      "R",
      "mordew_registry.R"
    )
  )
}

assignment <- function(
  name,
  value
) {
  paste(
    name,
    "<-",
    ascii_code(
      as_code(
        value
      )
    )
  )
}

ascii_code <- function(
  code
) {
  points <- utf8ToInt(
    code
  )
  chars <- intToUtf8(
    points,
    multiple = TRUE
  )
  chars[points > 127] <- sprintf(
    "\\U{%x}",
    points[points > 127]
  )
  paste(
    chars,
    collapse = ""
  )
}

as_code <- function(
  x,
  indent = ""
) {
  if (!is.list(x)) {
    return(
      deparse(
        x
      )
    )
  }
  if (length(x) == 0) {
    return(
      "list()"
    )
  }
  inner <- paste0(
    indent,
    "  "
  )
  keys <- if (!is.null(names(x))) {
    paste0(
      vapply(
        lapply(
          names(x),
          as.name
        ),
        deparse,
        "",
        backtick = TRUE
      ),
      " = "
    )
  }
  paste0(
    "list(\n",
    paste0(
      inner,
      keys,
      vapply(
        x,
        as_code,
        "",
        indent = inner
      ),
      collapse = ",\n"
    ),
    "\n",
    indent,
    ")"
  )
}
