# Code walkthrough: comments starting with #~ in R/, kept in
# dev/walkthrough.md. From the root of {mordew}:
#   source("dev/walkthrough.R")
#   walkthrough_in()   # puts the comments of the doc back into R/
#   walkthrough_out()  # moves them from R/ to the doc, before committing
# Tests: testthat::test_file("dev/tests/test-walkthrough.R")

walkthrough_out <- function(
  files = walkthrough_files(),
  doc = "dev/walkthrough.md"
) {
  stop_on_trailing_comment(
    files
  )
  sections <- read_walkthrough(
    doc
  )
  for (file in files) {
    lines <- readLines(
      file
    )
    comment <- is_walkthrough(
      lines
    )
    if (
      any(
        comment
      )
    ) {
      sections[[file]] <- comments_to_md(
        lines,
        comment
      )
      writeLines(
        lines[!comment],
        file
      )
    }
  }
  write_walkthrough(
    sections,
    doc
  )
}

stop_on_trailing_comment <- function(
  files
) {
  for (file in files) {
    if (
      any(
        is_walkthrough(
          tail(
            readLines(
              file
            ),
            1
          )
        )
      )
    ) {
      stop(
        file,
        ": the last walkthrough comment has no line below."
      )
    }
  }
}

walkthrough_in <- function(
  files = walkthrough_files(),
  doc = "dev/walkthrough.md"
) {
  sections <- read_walkthrough(
    doc
  )
  for (file in intersect(
    files,
    names(
      sections
    )
  )) {
    lines <- readLines(
      file
    )
    if (
      any(
        is_walkthrough(
          lines
        )
      )
    ) {
      stop(
        file,
        " already has walkthrough comments: run walkthrough_out() first."
      )
    }
    writeLines(
      insert_comments(
        lines,
        sections[[file]],
        file
      ),
      file
    )
  }
}

insert_comments <- function(
  lines,
  section,
  file
) {
  heading <- startsWith(
    section,
    "### "
  )
  block <- cumsum(
    heading
  )
  code <- trimws(
    lines
  )
  before <- vector(
    "list",
    length(
      lines
    )
  )
  headings <- section[heading]
  for (k in seq_along(
    headings
  )) {
    anchor <- sub(
      "^### `(.*)` #[0-9]+$",
      "\\1",
      headings[k]
    )
    occurrence <- as.integer(
      sub(
        "^.* #",
        "",
        headings[k]
      )
    )
    i <- which(
      code == anchor
    )[occurrence]
    if (
      is.na(
        i
      )
    ) {
      stop(
        file,
        ": the line `",
        anchor,
        "` #",
        occurrence,
        " of a comment is gone."
      )
    }
    before[[i]] <- paste0(
      sub(
        "\\S.*",
        "",
        lines[i]
      ),
      "#~ ",
      section[block == k & !heading & section != ""]
    )
  }
  unlist(
    Map(
      c,
      before,
      lines
    )
  )
}

walkthrough_files <- function() {
  list.files(
    c(
      "R",
      "inst/mordewexample"
    ),
    "\\.R$",
    recursive = TRUE,
    full.names = TRUE
  )
}

is_walkthrough <- function(
  lines
) {
  grepl(
    "^\\s*#~",
    lines
  )
}

comments_to_md <- function(
  lines,
  comment
) {
  code <- trimws(
    lines[!comment]
  )
  anchor <- cumsum(
    !comment
  )[comment] +
    1
  text <- sub(
    "^\\s*#~ ?",
    "",
    lines[comment]
  )
  unlist(
    lapply(
      unique(
        anchor
      ),
      function(i) {
        c(
          "",
          paste0(
            "### `",
            code[i],
            "` #",
            sum(
              head(
                code,
                i
              ) ==
                code[i]
            )
          ),
          "",
          text[anchor == i]
        )
      }
    )
  )
}

read_walkthrough <- function(
  doc
) {
  if (
    !file.exists(
      doc
    )
  ) {
    return(
      list()
    )
  }
  lines <- readLines(
    doc
  )
  is_file <- startsWith(
    lines,
    "## "
  )
  section <- cumsum(
    is_file
  )
  separator <- c(
    is_file[-1],
    FALSE
  )
  body <- section > 0 & !is_file & !separator
  stats::setNames(
    split(
      lines[body],
      section[body]
    ),
    sub(
      "^## ",
      "",
      lines[is_file]
    )
  )
}

write_walkthrough <- function(
  sections,
  doc
) {
  writeLines(
    c(
      "# Walkthrough",
      unlist(
        lapply(
          names(
            sections
          ),
          function(file) {
            c(
              "",
              paste(
                "##",
                file
              ),
              sections[[file]]
            )
          }
        )
      )
    ),
    doc
  )
}
