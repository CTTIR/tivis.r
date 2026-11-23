#' Discover TIVITA Recordings Below a Directory
#'
#' Walks a directory tree and returns one row per recording found. Only headers
#' are read, so scanning a large archive is cheap. A file is a recording when
#' its name ends in `_SpecCube.dat`.
#'
#' @param root Directory to search.
#' @param recursive Logical. Descend into subdirectories. Default `TRUE`.
#'
#' @return A data frame with one row per recording: `path`, `dir`, `timestamp`
#'   (`POSIXct`, see [tivis_parse_timestamp()]), `width`, `height`, `bands`,
#'   `file_size`, and `n_reference_images`. Zero rows if nothing matches. A
#'   cube whose header cannot be decoded is still listed, with `NA` for
#'   `width`, `height`, `bands` and `file_size`.
#'
#' @examples
#' # Build a tiny archive in a temporary directory from the bundled example
#' archive <- file.path(tempdir(), "tivita-archive")
#' dir.create(archive, showWarnings = FALSE)
#' invisible(file.copy(tivis_example_file(),
#'                     file.path(archive, "2000_01_01_12_00_00_SpecCube.dat")))
#' tivis_list_measurements(archive)
#' unlink(archive, recursive = TRUE)
#'
#' @export
tivis_list_measurements <- function(root, recursive = TRUE) {
  root <- .check_path(root, "root")
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
    # Same column types (and the same UTC time zone) as a populated result.
    return(data.frame(
      path = character(0), dir = character(0),
      timestamp = tivis_parse_timestamp(character(0)),
      width = integer(0), height = integer(0), bands = integer(0),
      file_size = numeric(0), n_reference_images = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  hdrs <- lapply(files, function(f) {
    tryCatch(
      tivis_read_header(f, validate = FALSE),
      error = function(e) {
        list(
          width = NA_integer_, height = NA_integer_,
          bands = NA_integer_, file_size = NA_real_
        )
      }
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
#' The file name records the wall-clock time of the acquisition computer and
#' carries no time-zone information. The digits are therefore taken as they
#' are and labelled with `tz`; no conversion takes place. Pass the time zone
#' of the recording site if the result is compared with other clocks. A
#' wall-clock time that does not exist in `tz`, such as one inside the hour
#' skipped at the start of daylight-saving time, cannot be represented and
#' may come back as `NA`; the default `"UTC"` has no such gaps.
#'
#' @param x Character vector of file or directory names. Full paths are
#'   accepted; only the last path component is inspected.
#' @param tz Time zone used to label the parsed wall-clock time. Default
#'   `"UTC"`.
#'
#' @return A `POSIXct` vector of the same length as `x`, `NA` where no valid
#'   timestamp is present (including `NA` input).
#'
#' @examples
#' tivis_parse_timestamp("2000_01_01_12_00_00_SpecCube.dat")
#'
#' # full paths work, and names without a timestamp give NA
#' tivis_parse_timestamp(c("/archive/2000_01_01_12_00_00_SpecCube.dat",
#'                         "notes.txt"))
#'
#' # label the wall-clock time with the recording site's time zone
#' tivis_parse_timestamp("2000_01_01_12_00_00_SpecCube.dat",
#'                       tz = "Europe/Berlin")
#'
#' @export
tivis_parse_timestamp <- function(x, tz = "UTC") {
  if (!is.character(tz) || length(tz) != 1L || is.na(tz)) {
    cli::cli_abort("{.arg tz} must be a single time-zone name.")
  }
  x <- basename(as.character(x))
  hit <- grepl("^[0-9]{4}(_[0-9]{2}){5}", x)
  out <- rep(NA_character_, length(x))
  # the stamp is always the first 19 characters: YYYY_MM_DD_HH_MM_SS
  out[hit] <- substr(x[hit], 1L, 19L)
  as.POSIXct(out, format = "%Y_%m_%d_%H_%M_%S", tz = tz)
}


#' Read a Complete TIVITA Recording
#'
#' Convenience wrapper returning the cube together with everything the Suite
#' stored alongside it: acquisition metadata and the paths of the exported
#' parameter images.
#'
#' The acquisition log is looked up beside the cube by replacing the
#' `_SpecCube.dat` suffix with `_meta.log`. A cube that does not follow this
#' naming scheme is read without metadata.
#'
#' @param path Path to a `*_SpecCube.dat` file.
#' @param bands Optional integer vector of band indices. `NULL` reads all.
#'
#' @return A plain list with
#'   * `cube`: the array returned by [tivis_read_cube()];
#'   * `wavelengths`: its wavelength axis in nanometres;
#'   * `metadata`: the result of [tivis_get_metadata()], an empty list when
#'     no log is found;
#'   * `references`: the result of [tivis_reference_images()];
#'   * `timestamp`: the result of [tivis_parse_timestamp()];
#'   * `path`: the input path.
#'
#' @examples
#' m <- tivis_measurement(tivis_example_file())
#' dim(m$cube)
#' m$metadata$Camera$Exposure
#'
#' @export
tivis_measurement <- function(path, bands = NULL) {
  cube <- tivis_read_cube(path, bands = bands)

  # Only a `*_SpecCube.dat` name identifies its sibling log. Without the
  # suffix sub() would return `path` unchanged and the binary cube itself
  # would be parsed as a log.
  suffix <- "_SpecCube[.]dat$"
  metadata <- if (grepl(suffix, path)) {
    tivis_get_metadata(sub(suffix, "_meta.log", path))
  } else {
    list()
  }

  list(
    cube = cube,
    wavelengths = attr(cube, "wavelengths"),
    metadata = metadata,
    references = tivis_reference_images(path),
    timestamp = tivis_parse_timestamp(basename(path)),
    path = path
  )
}
