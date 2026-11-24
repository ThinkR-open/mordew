reference_png <- function(
  draw
) {
  file <- tempfile(
    fileext = ".png"
  )
  on.exit(
    unlink(
      file
    )
  )
  grDevices::png(
    file,
    width = 800,
    height = 600,
    res = 96
  )
  draw()
  grDevices::dev.off()
  jsonlite::base64_enc(
    readBin(
      file,
      "raw",
      file.size(
        file
      )
    )
  )
}
