#' Read TIVITA Acquisition Metadata
#'
#' Parses a `*_meta.log` file written beside a TIVITA recording. The Suite
#' writes an INI-style file with German section and key names, `latin1`
#' encoding and comma decimal separators; all three are handled here.
#'
#' Values are converted as follows:
#'
#' * a value in double quotes is a string. The quotes are stripped and the
#'   content is returned verbatim, so identifiers and version strings such as
#'   `"0012"` or `"2.0"` keep their leading and trailing zeros;
#' * an unquoted number becomes a numeric, with a decimal comma or a decimal
#'   point (`7,000000` becomes `7`);
#' * an unquoted `TRUE` or `FALSE` (in any case) becomes a logical;
#' * anything else is returned as a trimmed string.
#'
#' Strings are returned in UTF-8. A file that is already valid UTF-8 is read
#' as such; any other file is taken to be `latin1`. Lines starting with `;`
#' or `#` are comments. Entries before the first section header are collected
#' in a section named `general`. If a key occurs twice in a section, the last
#' value wins.
#'
#' @param path Path to a `*_meta.log` file.
#'
#' @return A named list of sections, each a named list of entries. Returns an
#'   empty list if the file does not exist. A binary file, such as the cube
#'   itself, is rejected with an error.
#'
#' @examples
#' log_file <- system.file("extdata", "example_meta.log", package = "tivis.r")
#' if (nzchar(log_file)) str(tivis_get_metadata(log_file))
#'
#' @export
tivis_get_metadata <- function(path) {
  path <- .check_path(path)
  if (!file.exists(path) || dir.exists(path)) {
    return(list())
  }

  lines <- trimws(.read_log_lines(path))
  comment <- startsWith(lines, ";") | startsWith(lines, "#")
  lines <- lines[nzchar(lines) & !comment]

  out <- list()
  section <- "general"

  for (ln in lines) {
    if (startsWith(ln, "[") && endsWith(ln, "]")) {
      section <- trimws(substr(ln, 2L, nchar(ln) - 1L))
      # a list cannot be indexed by "", so `[]` falls back to the default
      if (!nzchar(section)) section <- "general"
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


# Read a log as UTF-8 strings. The Suite writes latin1 (its name carries a
# registered-trademark sign, byte 0xAE), but a log that was re-saved as UTF-8
# must not be decoded a second time, so each line is converted only when its
# bytes are not already valid UTF-8.
.read_log_lines <- function(path, call = rlang::caller_env()) {
  # A log is text. NUL bytes mean a binary file, typically the cube itself
  # passed by mistake; parsing it would return garbage keys without a word.
  if (any(readBin(path, what = "raw", n = 8192L) == as.raw(0L))) {
    cli::cli_abort(
      c(
        "{.file {basename(path)}} is not a TIVITA metadata log.",
        "x" = "It contains NUL bytes, as a binary file does.",
        "i" = "Expected the {.file *_meta.log} text file beside a cube."
      ),
      call = call
    )
  }
  lines <- readLines(path, warn = FALSE)
  legacy <- !validUTF8(lines)
  lines[legacy] <- iconv(lines[legacy], from = "latin1", to = "UTF-8")
  Encoding(lines) <- "UTF-8"
  if (length(lines)) {
    # drop a UTF-8 byte-order mark, which would hide the first section header
    lines[1L] <- sub("^\ufeff", "", lines[1L])
  }
  lines
}


# Coerce one raw INI value: quoted values are strings, bare values are mapped
# to logicals and numbers (German decimal comma included) where unambiguous.
.tivis_coerce <- function(x) {
  x <- trimws(x)
  # A value in double quotes is a string by declaration. Strip one layer of
  # quotes and stop: coercing the content would turn the identifier "0012"
  # into 12 and the version "2.0" into 2.
  if (nchar(x) >= 2L && startsWith(x, "\"") && endsWith(x, "\"")) {
    return(substr(x, 2L, nchar(x) - 1L))
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
#' When `path` is a cube whose name starts with a TIVITA timestamp
#' (`YYYY_MM_DD_HH_MM_SS_`), only the images carrying the same timestamp are
#' returned, so recordings that share one directory are kept apart. When
#' `path` is a directory, or a cube without a timestamp in its name, every
#' PNG in the directory is returned.
#'
#' @param path Path to a `*_SpecCube.dat` file, or to the directory holding it.
#'
#' @return A named character vector of existing file paths. Names are the
#'   parameter identifiers used by the Suite, for example `RGB-Image`,
#'   `Oxygenation`, `NIR-Perfusion`, `THI`, `TWI`, `OHI`. Zero-length if none
#'   are present.
#'
#' @examples
#' # Mimic a TIVITA export directory in a temporary location
#' rec <- file.path(tempdir(), "tivita-recording")
#' dir.create(rec, showWarnings = FALSE)
#' cube <- file.path(rec, "2000_01_01_12_00_00_SpecCube.dat")
#' invisible(file.copy(tivis_example_file(), cube))
#' invisible(file.create(file.path(rec, "2000_01_01_12_00_00_Oxygenation.png")))
#' tivis_reference_images(cube)
#' unlink(rec, recursive = TRUE)
#'
#' @export
tivis_reference_images <- function(path) {
  path <- .check_path(path)
  is_dir <- dir.exists(path)
  folder <- if (is_dir) path else dirname(path)
  if (!dir.exists(folder)) {
    cli::cli_abort("Directory not found: {.file {folder}}")
  }

  files <- list.files(
    folder, pattern = "[.]png$", full.names = TRUE, ignore.case = TRUE
  )

  # names look like <timestamp>_<Parameter>.png
  stamp <- "^[0-9]{4}(_[0-9]{2}){5}_"
  if (!is_dir && grepl(stamp, basename(path))) {
    # keep the images of this recording only: a directory may hold several
    own <- substr(basename(path), 1L, 20L)
    files <- files[startsWith(basename(files), own)]
  }
  if (!length(files)) return(character(0))

  labels <- sub("[.]png$", "", basename(files), ignore.case = TRUE)
  labels <- sub(stamp, "", labels)

  stats::setNames(files, labels)
}
