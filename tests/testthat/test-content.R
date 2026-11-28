test_that("content_text() makes a text block, one element per line", {
  expect_equal(
    unclass(
      content_text(
        c(
          "road",
          "trail"
        )
      )
    ),
    list(
      type = "text",
      text = "road\ntrail"
    )
  )
})

test_that("content_annotations() tells the audience, the priority and the last change", {
  expect_equal(
    unclass(
      content_text(
        "road",
        annotations = content_annotations(
          audience = "user",
          priority = 0.5,
          last_modified = as.POSIXct(
            "2025-01-12 15:00:58",
            tz = "UTC"
          )
        )
      )
    )$annotations,
    list(
      audience = list(
        "user"
      ),
      priority = 0.5,
      lastModified = "2025-01-12T15:00:58Z"
    )
  )
})

test_that("content_annotations() refuses what the specification does not allow", {
  expect_error(
    content_annotations(
      audience = "model"
    ),
    "The audience is user, assistant or both, not `model`.",
    fixed = TRUE
  )
  expect_error(
    content_annotations(
      priority = 2
    ),
    "The priority is a number from 0 to 1, not `2`.",
    fixed = TRUE
  )
})

test_that("content_image() makes an image block from a file or a plot", {
  path <- withr::local_tempfile(
    fileext = ".png"
  )
  grDevices::png(
    path
  )
  graphics::plot(
    1:3
  )
  grDevices::dev.off()
  grDevices::pdf(
    NULL
  )
  grDevices::dev.control(
    "enable"
  )
  graphics::plot(
    1:3
  )
  plot <- grDevices::recordPlot()
  grDevices::dev.off()

  expect_equal(
    unclass(
      content_image(
        path
      )
    ),
    list(
      type = "image",
      data = jsonlite::base64_enc(
        readBin(
          path,
          "raw",
          file.size(
            path
          )
        )
      ),
      mimeType = "image/png"
    )
  )
  expect_equal(
    unclass(
      content_image(
        plot
      )
    ),
    image_content(
      plot
    )[[1]]
  )
})

test_that("content_audio() makes an audio block, its MIME type from the file or given", {
  wav <- withr::local_tempfile(
    fileext = ".wav"
  )
  writeBin(
    as.raw(
      1:4
    ),
    wav
  )
  raw <- withr::local_tempfile(
    fileext = ".bin"
  )
  writeBin(
    as.raw(
      1:4
    ),
    raw
  )

  expect_equal(
    unclass(
      content_audio(
        wav
      )
    ),
    list(
      type = "audio",
      data = "AQIDBA==",
      mimeType = "audio/wav"
    )
  )
  expect_equal(
    content_audio(
      raw,
      mime_type = "audio/ogg"
    )$mimeType,
    "audio/ogg"
  )
  expect_error(
    content_audio(
      raw
    ),
    "Give the MIME type of `",
    fixed = TRUE
  )
})

test_that("content_resource_link() makes a link to a resource", {
  expect_equal(
    unclass(
      content_resource_link(
        "runlog://runs/2024",
        "runs",
        description = "The runs of 2024.",
        mime_type = "text/plain",
        size = 1024
      )
    ),
    list(
      type = "resource_link",
      uri = "runlog://runs/2024",
      name = "runs",
      description = "The runs of 2024.",
      mimeType = "text/plain",
      size = 1024
    )
  )
})

test_that("content_resource() embeds a resource as text or as a blob", {
  expect_equal(
    unclass(
      content_resource(
        "runlog://surfaces",
        text = "road",
        mime_type = "text/plain"
      )
    ),
    list(
      type = "resource",
      resource = list(
        uri = "runlog://surfaces",
        mimeType = "text/plain",
        text = "road"
      )
    )
  )
  expect_equal(
    content_resource(
      "runlog://track.gpx",
      blob = as.raw(
        1:4
      )
    )$resource,
    list(
      uri = "runlog://track.gpx",
      blob = "AQIDBA=="
    )
  )
  expect_error(
    content_resource(
      "runlog://surfaces"
    ),
    "Give `text` or `blob`, not both nor neither.",
    fixed = TRUE
  )
})

test_that("tool_result() sends the content blocks of a content tool", {
  expect_equal(
    tool_result(
      list(
        content_text(
          "Runs of 2024"
        ),
        content_resource_link(
          "runlog://runs/2024",
          "runs"
        )
      ),
      "content"
    ),
    list(
      content = list(
        list(
          type = "text",
          text = "Runs of 2024"
        ),
        list(
          type = "resource_link",
          uri = "runlog://runs/2024",
          name = "runs"
        )
      )
    )
  )
  expect_true(
    tool_result(
      list(
        "Runs of 2024"
      ),
      "content"
    )$isError
  )
})
