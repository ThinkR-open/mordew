#' Install the development dependencies
#'
#' Installs the missing packages among those mordew suggests: the tooling
#' used while developing a mordew package.
#'
#' @param dev_deps Packages to install when missing.
#'
#' @export
install_dev_deps <- function(
  dev_deps = suggested_packages()
) {
  utils::install.packages(
    setdiff(
      dev_deps,
      basename(
        find.package(
          dev_deps,
          quiet = TRUE
        )
      )
    )
  )
}

suggested_packages <- function() {
  suggests <- utils::packageDescription(
    "mordew",
    fields = "Suggests"
  )
  trimws(
    sub(
      "\\(.*",
      "",
      strsplit(
        suggests,
        ","
      )[[1]]
    )
  )
}
