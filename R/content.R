#' Content blocks of a tool result
#'
#' A tool tagged `@mcpReturns content` returns a list of these blocks, sent
#' as they are in the `content` of its result: text, an image, audio, a link
#' to a resource, or an embedded resource, each with optional annotations.
#'
#' @param text Character vector, one element per line.
#' @param annotations `content_annotations()`, or `NULL`.
#'
#' @return A content block, or for `content_annotations()` the annotations
#'   of one.
#'
#' @name content_blocks
NULL

#' @rdname content_blocks
#' @export
content_text <- function(
  text,
  annotations = NULL
) {
  content_block(
    text_content(
      paste(
        text,
        collapse = "\n"
      )
    )[[1]],
    annotations
  )
}

#' @rdname content_blocks
#' @param x A ggplot, a recorded plot, or the path to an image file.
#' @param mime_type MIME type, guessed from the file extension when `NULL`.
#' @export
content_image <- function(
  x,
  mime_type = NULL,
  annotations = NULL
) {
  content_block(
    if (is.character(x)) {
      file_block(
        "image",
        x,
        mime_type,
        image_types
      )
    } else {
      image_content(
        x
      )[[1]]
    },
    annotations
  )
}

#' @rdname content_blocks
#' @param path Path to an audio file.
#' @export
content_audio <- function(
  path,
  mime_type = NULL,
  annotations = NULL
) {
  content_block(
    file_block(
      "audio",
      path,
      mime_type,
      audio_types
    ),
    annotations
  )
}

#' @rdname content_blocks
#' @param uri URI of the resource.
#' @param name,title,description Name, display name and description of the
#'   resource.
#' @param size Size of the resource in bytes.
#' @export
content_resource_link <- function(
  uri,
  name,
  title = NULL,
  description = NULL,
  mime_type = NULL,
  size = NULL,
  annotations = NULL
) {
  content_block(
    Filter(
      Negate(
        is.null
      ),
      list(
        type = "resource_link",
        uri = uri,
        name = name,
        title = title,
        description = description,
        mimeType = mime_type,
        size = size
      )
    ),
    annotations
  )
}

#' @rdname content_blocks
#' @param blob Raw vector, the binary content of the resource.
#' @export
content_resource <- function(
  uri,
  text = NULL,
  blob = NULL,
  mime_type = NULL,
  annotations = NULL
) {
  if (is.null(text) == is.null(blob)) {
    stop(
      "Give `text` or `blob`, not both nor neither.",
      call. = FALSE
    )
  }
  content_block(
    list(
      type = "resource",
      resource = Filter(
        Negate(
          is.null
        ),
        list(
          uri = uri,
          mimeType = mime_type,
          text = if (!is.null(text)) {
            sanitize_text(
              paste(
                text,
                collapse = "\n"
              )
            )
          },
          blob = if (!is.null(blob)) {
            jsonlite::base64_enc(
              blob
            )
          }
        )
      )
    ),
    annotations
  )
}

#' @rdname content_blocks
#' @param audience Who the block is for: `"user"`, `"assistant"` or both.
#' @param priority How important the block is, from 0 to 1.
#' @param last_modified When it last changed: a date-time, or an ISO 8601
#'   string.
#' @export
content_annotations <- function(
  audience = NULL,
  priority = NULL,
  last_modified = NULL
) {
  wrong <- setdiff(
    audience,
    c(
      "user",
      "assistant"
    )
  )
  if (length(wrong) > 0) {
    stop(
      "The audience is user, assistant or both, not `",
      wrong[[1]],
      "`.",
      call. = FALSE
    )
  }
  if (
    !is.null(priority) &&
      !(is.numeric(priority) &&
        length(priority) == 1 &&
        priority >= 0 &&
        priority <= 1)
  ) {
    stop(
      "The priority is a number from 0 to 1, not `",
      format(
        priority
      ),
      "`.",
      call. = FALSE
    )
  }
  if (inherits(last_modified, "POSIXt")) {
    last_modified <- iso_time(
      last_modified
    )
  }
  Filter(
    Negate(
      is.null
    ),
    list(
      audience = if (!is.null(audience)) {
        as.list(
          audience
        )
      },
      priority = priority,
      lastModified = last_modified
    )
  )
}

content_block <- function(
  block,
  annotations
) {
  if (length(annotations) > 0) {
    block$annotations <- annotations
  }
  structure(
    block,
    class = "mordew_content"
  )
}

file_block <- function(
  type,
  path,
  mime_type,
  types
) {
  if (is.null(mime_type)) {
    mime_type <- types[tolower(
      sub(
        "^.*[.]([^.]*)$|^[^.]*$",
        "\\1",
        basename(
          path
        )
      )
    )]
  }
  if (is.na(mime_type)) {
    stop(
      "Give the MIME type of `",
      basename(
        path
      ),
      "` with `mime_type`.",
      call. = FALSE
    )
  }
  list(
    type = type,
    data = file_base64(
      path
    ),
    mimeType = unname(
      mime_type
    )
  )
}

image_types <- c(
  png = "image/png",
  jpg = "image/jpeg",
  jpeg = "image/jpeg",
  gif = "image/gif",
  webp = "image/webp",
  svg = "image/svg+xml"
)

audio_types <- c(
  wav = "audio/wav",
  mp3 = "audio/mpeg",
  ogg = "audio/ogg",
  flac = "audio/flac",
  m4a = "audio/mp4",
  webm = "audio/webm"
)
