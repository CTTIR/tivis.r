#' Read a TIVITA Suite Hyperspectral Cube
#'
#' Reads a `*_SpecCube.dat` file written by the Diaspective Vision TIVITA
#' Suite. Unlike Cubert `.cu3s` session files, the TIVITA container is a plain
#' binary format, so this package needs no vendor SDK and no compiled code.
#'
#' @section File format:
#' The format was determined empirically from reference captures and validated
#' against the TIVITA Suite's own `_RGB-Image.png` exports:
#'
#' * a 12-byte header of three **big-endian** `uint32` values giving
#'   `width`, `height` and `bands`;
#' * followed by **big-endian** `float32` samples;
#' * stored **band-interleaved-by-pixel** (BIP): all bands of one pixel are
#'   contiguous, pixels run in row-major order (x varies fastest).
#'
#' Values are calibrated reflectance. They are normally within `[0, 1]` but may
#' fall slightly below zero or exceed one in specular and saturated regions, so
#' the reader does not clamp them.
#'
#' @param path Path to a `*_SpecCube.dat` file.
#' @param bands Optional integer vector of band indices to read. `NULL`
#'   (default) reads every band. Selecting a subset still reads the whole file,
#'   but returns only the requested bands.
#' @param validate Logical. Check that the file size matches the header before
#'   reading. Default `TRUE`; there is no good reason to disable it.
#'
#' @return A numeric array with dimensions `(rows, cols, bands)` — matching the
#'   convention used by `hyperspectR::hsi_cube()` — carrying a `wavelengths`
#'   attribute in nanometres.
#'
#' @seealso [tivis_read_header()] for header-only access,
#'   [tivis_get_wavelengths()] for the wavelength axis.
#'
#' @examples
#' f <- tivis_example_file()
#' cube <- tivis_read_cube(f)
#' dim(cube)
#' range(attr(cube, "wavelengths"))
#'
#' @export
tivis_read_cube <- function(path, bands = NULL, validate = TRUE) {
  hdr <- tivis_read_header(path, validate = validate)
  w <- hdr$width
  h <- hdr$height
  nb <- hdr$bands

  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)

  # skip the header, then read every sample
  readBin(con, what = "raw", n = 12L)
  n_values <- as.double(w) * as.double(h) * as.double(nb)
  v <- readBin(con, what = "double", n = n_values, size = 4L, endian = "big")

  if (length(v) != n_values) {
    cli::cli_abort(c(
      "Truncated cube: {.file {basename(path)}}.",
      "x" = "Header promises {.val {n_values}} samples, file yielded {.val {length(v)}}."
    ))
  }

  keep <- if (is.null(bands)) seq_len(nb) else .check_bands(bands, nb)

  # BIP -> (rows, cols, band). Band b occupies every nb-th sample starting at b;
  # the resulting pixel run is row-major (x fastest), so fill an (w x h) matrix
  # and transpose to get (rows, cols).
  out <- array(0.0, dim = c(h, w, length(keep)))
  for (k in seq_along(keep)) {
    plane <- v[seq.int(from = keep[k], to = length(v), by = nb)]
    out[, , k] <- t(matrix(plane, nrow = w, ncol = h))
  }

  attr(out, "wavelengths") <- tivis_get_wavelengths(nb)[keep]
  out
}


#' Read a TIVITA Cube Header
#'
#' Parses the 12-byte header of a `*_SpecCube.dat` file without reading the
#' sample data, which makes it cheap enough to scan large archives.
#'
#' @param path Path to a `*_SpecCube.dat` file.
#' @param validate Logical. Verify that the file size equals
#'   `12 + width * height * bands * 4`. Default `TRUE`.
#'
#' @return A named list with `width`, `height`, `bands`, `n_values` and
#'   `file_size`.
#'
#' @examples
#' tivis_read_header(tivis_example_file())
#'
#' @export
tivis_read_header <- function(path, validate = TRUE) {
  if (!file.exists(path)) {
    cli::cli_abort("File not found: {.file {path}}")
  }

  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  dims <- readBin(con, what = "integer", n = 3L, size = 4L, endian = "big")

  if (length(dims) < 3L || anyNA(dims) || any(dims <= 0L)) {
    cli::cli_abort(c(
      "Not a readable TIVITA cube: {.file {basename(path)}}.",
      "x" = "The first 12 bytes do not decode to three positive big-endian integers."
    ))
  }

  size <- file.size(path)
  n_values <- as.double(dims[1]) * as.double(dims[2]) * as.double(dims[3])
  expected <- 12 + n_values * 4

  if (validate && size != expected) {
    cli::cli_abort(c(
      "Header does not describe {.file {basename(path)}}.",
      "i" = "Header says {dims[1]} x {dims[2]} x {dims[3]}, implying {.val {expected}} bytes.",
      "x" = "The file is {.val {size}} bytes."
    ))
  }

  list(
    width = dims[1], height = dims[2], bands = dims[3],
    n_values = n_values, file_size = size
  )
}


#' TIVITA Wavelength Axis
#'
#' The TIVITA Tissue camera samples 500-995 nm in 5 nm steps. The mapping was
#' confirmed empirically: correlating each band against the TIVITA Suite's own
#' greyscale RGB export peaks at band 12, i.e. 555 nm, which is where human
#' photopic luminous efficiency peaks.
#'
#' @param n_bands Integer number of bands. Default `100L`, the native count.
#'
#' @return Numeric vector of band centre wavelengths in nanometres.
#'
#' @examples
#' range(tivis_get_wavelengths())
#'
#' @export
tivis_get_wavelengths <- function(n_bands = 100L) {
  n_bands <- as.integer(n_bands)
  if (length(n_bands) != 1L || is.na(n_bands) || n_bands <= 0L) {
    cli::cli_abort("{.arg n_bands} must be a single positive integer.")
  }
  500 + 5 * (seq_len(n_bands) - 1)
}


#' Is the TIVITA Reader Available?
#'
#' Present for symmetry with `cuvis.r::cuvis_available()`. TIVITA support is
#' pure R with no vendor SDK, so this is always `TRUE`.
#'
#' @return `TRUE`, invisibly usable in conditionals.
#'
#' @examples
#' tivis_available()
#'
#' @export
tivis_available <- function() TRUE


#' Path to the Bundled Example Cube
#'
#' A small synthetic cube in genuine TIVITA layout, generated by
#' `data-raw/make-fixture.R`. It ships with the package so examples, tests and
#' vignettes run without access to clinical recordings.
#'
#' @return Path to the bundled `*_SpecCube.dat` file.
#'
#' @examples
#' tivis_example_file()
#'
#' @export
tivis_example_file <- function() {
  p <- system.file("extdata", "example_SpecCube.dat", package = "tivis.r")
  if (!nzchar(p)) {
    cli::cli_abort("Example file not found. Is {.pkg tivis.r} installed correctly?")
  }
  p
}


# Validate a band selection against the band count.
.check_bands <- function(bands, nb) {
  bands <- as.integer(bands)
  if (anyNA(bands)) {
    cli::cli_abort("{.arg bands} must be coercible to integers without NAs.")
  }
  bad <- bands[bands < 1L | bands > nb]
  if (length(bad)) {
    cli::cli_abort(c(
      "{.arg bands} out of range.",
      "x" = "Requested {.val {bad}}, but the cube has {nb} bands."
    ))
  }
  bands
}
