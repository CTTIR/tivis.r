#' Read TIVITA Acquisition Metadata
#'
#' Parses a `*_meta.log` file written beside a TIVITA recording. The Suite
#' writes an INI-style file with German section and key names, `latin1`
#' encoding and comma decimal separators; all three are handled here.
#'
#' Numeric-looking values are converted to numbers (`"7,000000"` becomes
#' `7`), `TRUE`/`FALSE` become logicals, and surrounding quotes are stripped.
#' Unrecognised values are returned as trimmed strings.
#'
#' @param path Path to a `*_meta.log` file.
#'
#' @return A named list of sections, each a named list of entries. Returns an
#'   empty list if the file does not exist.
#'
#' @examples
#' log_file <- system.file("extdata", "example_meta.log", package = "tivis.r")
#' if (nzchar(log_file)) str(tivis_get_metadata(log_file))
#'
#' @export
tivis_get_metadata <- function(path) {
  if (!file.exists(path)) {
    return(list())
  }

  # The Suite writes latin1; reading as UTF-8 mangles the registered-trademark
  # sign in "TIVITA(R) Suite".
  lines <- readLines(path, encoding = "latin1", warn = FALSE)
  lines <- trimws(lines)
  lines <- lines[nzchar(lines) & !startsWith(lines, ";") & !startsWith(lines, "#")]

  out <- list()
  section <- "general"

  for (ln in lines) {
    if (startsWith(ln, "[") && endsWith(ln, "]")) {
      section <- substr(ln, 2L, nchar(ln) - 1L)
      if (is.null(out[[section]])) out[[section]] <- list()
      next
    }
    pos <- regexpr("=", ln, fixed = TRUE)
    if (pos < 1L) next

    key <- trimws(substr(ln, 1L, pos - 1L))
    val <- trimws(substr(ln, pos + 1L, nchar(ln)))
    if (!nzchar(key)) next

    if (is.null(out[[section]])) out[[section]] <- list()
    out[[section]][[key]] <- .tivis_coerce(val)
  }

  out
}


# Coerce one raw INI value: strip quotes, map booleans, convert German decimals.
.tivis_coerce <- function(x) {
  x <- trimws(x)
  # strip a single layer of surrounding double quotes
  if (nchar(x) >= 2L && startsWith(x, "\"") && endsWith(x, "\"")) {
    x <- substr(x, 2L, nchar(x) - 1L)
  }
  if (!nzchar(x)) return("")

  up <- toupper(x)
  if (up == "TRUE") return(TRUE)
  if (up == "FALSE") return(FALSE)

  # German decimal comma, e.g. "7,000000" -> 7. Only when the string is
  # otherwise purely numeric, so text containing commas is left alone.
  if (grepl("^[+-]?[0-9]+,[0-9]+$", x)) {
    return(as.numeric(sub(",", ".", x, fixed = TRUE)))
  }
  if (grepl("^[+-]?[0-9]+$", x) || grepl("^[+-]?[0-9]*\\.[0-9]+$", x)) {
    return(as.numeric(x))
  }

  x
}


#' Locate the Parameter Images Beside a Recording
#'
#' The TIVITA Suite exports its computed parameter maps as PNGs next to each
#' cube: an RGB rendering plus tissue indices. These are the Suite's own
#' results and are useful as a reference when validating independently
#' computed indices.
#'
#' @param path Path to a `*_SpecCube.dat` file, or to the directory holding it.
#'
#' @return A named character vector of existing file paths. Names are the
#'   parameter identifiers used by the Suite, for example `RGB-Image`,
#'   `Oxygenation`, `NIR-Perfusion`, `THI`, `TWI`, `OHI`. Zero-length if none
#'   are present.
#'
#' @examples
#' \donttest{
#' # tivis_reference_images("/path/to/2019_11_25_13_29_24_SpecCube.dat")
#' }
#'
#' @export
tivis_reference_images <- function(path) {
  dir <- if (dir.exists(path)) path else dirname(path)
  if (!dir.exists(dir)) {
    cli::cli_abort("Directory not found: {.file {dir}}")
  }

  files <- list.files(dir, pattern = "[.]png$", full.names = TRUE)
  if (!length(files)) return(character(0))

  # names look like <timestamp>_<Parameter>.png
  labels <- sub("[.]png$", "", basename(files))
  labels <- sub("^[0-9]{4}(_[0-9]{2}){5}_", "", labels)

  stats::setNames(files, labels)
}
