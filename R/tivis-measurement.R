#' Discover TIVITA Recordings Below a Directory
#'
#' Walks a directory tree and returns one row per recording found. Only headers
#' are read, so scanning a large archive is cheap.
#'
#' @param root Directory to search.
#' @param recursive Logical. Descend into subdirectories. Default `TRUE`.
#'
#' @return A data frame with one row per recording: `path`, `dir`, `timestamp`,
#'   `width`, `height`, `bands`, `file_size`, and `n_reference_images`. Zero
#'   rows if nothing matches.
#'
#' @examples
#' \donttest{
#' # tivis_list_measurements("/archive/tivita")
#' }
#'
#' @export
tivis_list_measurements <- function(root, recursive = TRUE) {
  if (!dir.exists(root)) {
    cli::cli_abort("Directory not found: {.file {root}}")
  }

  # NOTE: list.files() takes a regular expression, not a glob.
  files <- list.files(
    root,
    pattern = "_SpecCube[.]dat$",
    recursive = recursive,
    full.names = TRUE
  )

  if (!length(files)) {
    return(data.frame(
      path = character(0), dir = character(0), timestamp = as.POSIXct(character(0)),
      width = integer(0), height = integer(0), bands = integer(0),
      file_size = numeric(0), n_reference_images = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  hdrs <- lapply(files, function(f) {
    tryCatch(
      tivis_read_header(f, validate = FALSE),
      error = function(e) list(width = NA_integer_, height = NA_integer_,
                               bands = NA_integer_, file_size = NA_real_)
    )
  })

  data.frame(
    path = files,
    dir = dirname(files),
    timestamp = tivis_parse_timestamp(basename(files)),
    width = vapply(hdrs, function(h) as.integer(h$width), integer(1)),
    height = vapply(hdrs, function(h) as.integer(h$height), integer(1)),
    bands = vapply(hdrs, function(h) as.integer(h$bands), integer(1)),
    file_size = vapply(hdrs, function(h) as.numeric(h$file_size), numeric(1)),
    n_reference_images = vapply(
      files, function(f) length(tivis_reference_images(f)), integer(1),
      USE.NAMES = FALSE
    ),
    stringsAsFactors = FALSE
  )
}


#' Parse a TIVITA Filename Timestamp
#'
#' TIVITA names every artefact of a recording `YYYY_MM_DD_HH_MM_SS_<what>`.
#' This extracts the acquisition time from such a name.
#'
#' @param x Character vector of file or directory names.
#'
#' @return A `POSIXct` vector, `NA` where no timestamp is present.
#'
#' @examples
#' tivis_parse_timestamp("2019_11_25_13_29_24_SpecCube.dat")
#'
#' @export
tivis_parse_timestamp <- function(x) {
  m <- regmatches(x, regexpr("^[0-9]{4}(_[0-9]{2}){5}", x))
  out <- rep(NA_character_, length(x))
  hit <- vapply(regexpr("^[0-9]{4}(_[0-9]{2}){5}", x), function(i) i > 0L, logical(1))
  out[hit] <- m
  as.POSIXct(out, format = "%Y_%m_%d_%H_%M_%S", tz = "UTC")
}


#' Read a Complete TIVITA Recording
#'
#' Convenience wrapper returning the cube together with everything the Suite
#' stored alongside it: acquisition metadata and the paths of the exported
#' parameter images.
#'
#' @param path Path to a `*_SpecCube.dat` file.
#' @param bands Optional integer vector of band indices. `NULL` reads all.
#'
#' @return A list with `cube`, `wavelengths`, `metadata`, `references`,
#'   `timestamp` and `path`.
#'
#' @examples
#' m <- tivis_measurement(tivis_example_file())
#' dim(m$cube)
#'
#' @export
tivis_measurement <- function(path, bands = NULL) {
  cube <- tivis_read_cube(path, bands = bands)
  log_file <- sub("_SpecCube[.]dat$", "_meta.log", path)

  list(
    cube = cube,
    wavelengths = attr(cube, "wavelengths"),
    metadata = tivis_get_metadata(log_file),
    references = tivis_reference_images(path),
    timestamp = tivis_parse_timestamp(basename(path)),
    path = path
  )
}
