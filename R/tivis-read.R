#' Read a TIVITA Suite Hyperspectral Cube
#'
#' Reads a `*_SpecCube.dat` file written by the Diaspective Vision TIVITA
#' Suite. Unlike Cubert `.cu3s` session files, the TIVITA container is a plain
#' binary format, so this package needs no vendor SDK and no compiled code.
#'
#' @section File format:
#' The vendor publishes no specification. The format was determined
#' empirically from reference captures, by measuring the periodicity of the
#' sample stream itself:
#'
#' * a 12-byte header of three **big-endian** `uint32` values giving
#'   `width`, `height` and `bands`;
#' * followed by **big-endian** `float32` samples;
#' * stored **band-interleaved-by-pixel** (BIP): all bands of one pixel are
#'   contiguous (the autocorrelation of the raw stream peaks at a lag equal to
#'   the band count);
#' * with column-major spatial planes, y varying fastest (the autocorrelation
#'   of an extracted band plane peaks at a lag equal to the image height).
#'   Device/export qualification requires an independent geometry fixture.
#'
#' An earlier comparison with the Suite's `_RGB-Image.png` export was
#' withdrawn as evidence: that image is rotated and rescaled relative to the
#' cube and cannot serve as pixel-level ground truth (see `NEWS.md`).
#'
#' Values are calibrated reflectance. They are normally within `[0, 1]` but may
#' fall slightly below zero or exceed one in specular and saturated regions, so
#' the reader does not clamp them.
#'
#' @section Memory:
#' Samples are stored as 4-byte floats and returned as 8-byte doubles, so a
#' native 640 x 480 x 100 cube of 123 MB occupies about 246 MB in R. The file
#' is read in blocks of image columns, so little working memory is needed
#' beyond the returned array, and a band subset never holds the bands it
#' drops.
#'
#' @param path Path to a `*_SpecCube.dat` file.
#' @param bands Optional integer vector of band indices to read, in the order
#'   wanted. `NULL` (default) reads every band. Selecting a subset still reads
#'   through the whole file, but keeps only the requested bands in memory.
#'   Fractional, missing and out-of-range indices are rejected.
#' @param validate Logical. Check that the file size matches the header before
#'   reading. Default `TRUE`; there is no good reason to disable it. With
#'   `FALSE`, a file longer than the header implies is read up to the size the
#'   header describes; a shorter file is still rejected as truncated.
#'
#' @return A numeric array with dimensions `(rows, cols, bands)` — matching the
#'   convention used by `hyperspectR::hsi_cube()` — carrying a `wavelengths`
#'   attribute in nanometres. The wavelengths are the nominal axis from
#'   [tivis_get_wavelengths()], not values stored in the file.
#'
#' @seealso [tivis_read_header()] for header-only access,
#'   [tivis_get_wavelengths()] for the wavelength axis,
#'   [tivis_read_cube_profiled()] to read without assuming a wavelength axis.
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

  # Validate the selection before touching the samples: a full cube is
  # about 123 MB, and a bad `bands` should fail without reading it.
  keep <- if (is.null(bands)) seq_len(nb) else .check_bands(bands, nb)

  # readBin() allocates its result up front. Never ask for more samples than
  # the file can hold, or a corrupt header read with `validate = FALSE` would
  # request an arbitrarily large vector.
  n_values <- hdr$n_values
  n_available <- floor((hdr$file_size - 12) / 4)
  if (n_available < n_values) {
    .abort_truncated(path, n_values, n_available)
  }

  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  readBin(con, what = "raw", n = 12L) # skip the header

  # BIP -> (rows, cols, band). The file order is band fastest, then y, then
  # x: all bands of a pixel are contiguous, and within a plane the pixels are
  # COLUMN-major, so successive pixels run down a column rather than across a
  # row. Measured directly from the sample stream -- autocorrelation of an
  # extracted plane peaks at lag 480 (the height) at r = 0.99, against
  # r = 0.43 at lag 640 (the width). A block of whole columns is therefore a
  # (band, y, x) array, and permuting it to (y, x, band) needs no transpose.
  #
  # Reading block by block keeps the peak memory near the size of the result
  # instead of holding every sample twice, and a band subset never
  # materialises the bands it drops.
  out <- array(0.0, dim = c(h, w, length(keep)))
  per_column <- as.double(h) * as.double(nb)
  step <- .chunk_columns(per_column, w)
  for (first in seq.int(1L, w, by = step)) {
    cols <- first:min(first + step - 1L, w)
    n <- per_column * length(cols)
    v <- readBin(con, what = "double", n = n, size = 4L, endian = "big")
    if (length(v) != n) {
      .abort_truncated(path, n_values, (first - 1) * per_column + length(v))
    }
    dim(v) <- c(nb, h, length(cols))
    if (!is.null(bands)) v <- v[keep, , , drop = FALSE]
    out[, cols, ] <- aperm(v, c(2L, 3L, 1L))
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
#' @return A named list with `width`, `height`, `bands` (integers),
#'   `n_values` (the number of samples the header implies,
#'   `width * height * bands`) and `file_size` (bytes).
#'
#' @examples
#' tivis_read_header(tivis_example_file())
#'
#' @export
tivis_read_header <- function(path, validate = TRUE) {
  path <- .check_path(path)
  if (!file.exists(path)) {
    cli::cli_abort("File not found: {.file {path}}")
  }
  if (dir.exists(path)) {
    cli::cli_abort(c(
      "{.file {path}} is a directory, not a cube file.",
      "i" = "Use {.fn tivis_list_measurements} to find the cubes below it."
    ))
  }

  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  dims <- readBin(con, what = "integer", n = 3L, size = 4L, endian = "big")

  if (length(dims) < 3L || anyNA(dims) || any(dims <= 0L)) {
    cli::cli_abort(c(
      "Not a readable TIVITA cube: {.file {basename(path)}}.",
      "x" = paste(
        "The first 12 bytes do not decode to three positive",
        "big-endian integers."
      )
    ))
  }

  size <- file.size(path)
  n_values <- as.double(dims[1]) * as.double(dims[2]) * as.double(dims[3])
  expected <- 12 + n_values * 4

  if (validate && size != expected) {
    cli::cli_abort(c(
      "Header does not describe {.file {basename(path)}}.",
      "i" = paste(
        "Header says {dims[1]} x {dims[2]} x {dims[3]},",
        "implying {.val {expected}} bytes."
      ),
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
#' Returns the nominal wavelength axis this reader assumes for a TIVITA
#' Tissue recording: band `i` is centred at `500 + 5 * (i - 1)` nm, that is
#' 500-995 nm in 5 nm steps for the native 100 bands.
#'
#' The cube file stores no wavelengths, so the axis is an assumption of the
#' reader and is not read from, or checked against, the recording. An earlier
#' statement that the mapping had been confirmed against the Suite's RGB
#' export was withdrawn together with that comparison (see `NEWS.md`). Use
#' [tivis_read_cube_profiled()] when the axis must be declared explicitly
#' instead of assumed, for example for another TIVITA camera model.
#'
#' @param n_bands Number of bands, a single positive whole number. Default
#'   `100L`, the native count.
#'
#' @return Numeric vector of nominal band centre wavelengths in nanometres.
#'
#' @examples
#' range(tivis_get_wavelengths())
#'
#' @export
tivis_get_wavelengths <- function(n_bands = 100L) {
  n <- suppressWarnings(as.integer(n_bands))
  fractional <- is.numeric(n_bands) && !isTRUE(all(n_bands == n))
  if (length(n) != 1L || is.na(n) || n <= 0L || fractional) {
    cli::cli_abort("{.arg n_bands} must be a single positive integer.")
  }
  500 + 5 * (seq_len(n) - 1)
}


#' Is the TIVITA Reader Available?
#'
#' Present for symmetry with `cuvis.r::cuvis_available()`. TIVITA support is
#' pure R with no vendor SDK, so this is always `TRUE`.
#'
#' @return Always `TRUE` (a single logical value), for use in conditionals.
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
    cli::cli_abort(
      "Example file not found. Is {.pkg tivis.r} installed correctly?"
    )
  }
  p
}


# Validate a single path argument. `arg` names it in the message.
.check_path <- function(path, arg = "path", call = rlang::caller_env()) {
  if (!is.character(path) || length(path) != 1L || is.na(path) ||
        !nzchar(path)) {
    cli::cli_abort(
      "{.arg {arg}} must be a single path (one non-missing string).",
      call = call
    )
  }
  path
}

# Number of image columns to read per block. One column holds `per_column`
# samples (height x bands); a block holds about 1 million samples (8 MB as
# doubles) unless the internal option `tivis.r.chunk_values` says otherwise.
.chunk_columns <- function(per_column, w) {
  budget <- getOption("tivis.r.chunk_values", 1e6)
  if (!is.numeric(budget) || length(budget) != 1L || is.na(budget)) {
    budget <- 1e6
  }
  as.integer(min(w, max(1, floor(budget / per_column))))
}

# Signal a cube whose file holds fewer samples than its header promises.
.abort_truncated <- function(path, expected, found,
                             call = rlang::caller_env()) {
  cli::cli_abort(
    c(
      "Truncated cube: {.file {basename(path)}}.",
      "x" = paste(
        "Header promises {.val {expected}} samples,",
        "the file holds {.val {found}}."
      )
    ),
    call = call
  )
}

# Validate a band selection against the band count.
.check_bands <- function(bands, nb, call = rlang::caller_env()) {
  ints <- suppressWarnings(as.integer(bands))
  # as.integer() truncates, so 2.7 would silently select band 2
  fractional <- is.numeric(bands) && !isTRUE(all(bands == ints))
  if (anyNA(ints) || fractional) {
    cli::cli_abort(
      "{.arg bands} must be whole-number band indices without NAs.",
      call = call
    )
  }
  bands <- ints
  bad <- bands[bands < 1L | bands > nb]
  if (length(bad)) {
    cli::cli_abort(
      c(
        "{.arg bands} out of range.",
        "x" = "Requested {.val {bad}}, but the cube has {nb} band{?s}."
      ),
      call = call
    )
  }
  bands
}

#' Read a TIVITA Cube with Explicit Spectral Evidence
#'
#' Variant of [tivis_read_cube()] that does not infer the wavelength axis.
#' The caller either declares the wavelengths explicitly or the cube is
#' returned with `NA` wavelengths, and the provenance is recorded in a
#' `wavelength_evidence` attribute.
#'
#' @param path Path to a `*_SpecCube.dat` file.
#' @param wavelengths Explicit numeric vector with one wavelength per source
#'   band, or `NULL` (default) when the wavelengths are unknown.
#' @param bands Optional integer vector of source band indices. `NULL`
#'   (default) reads every band.
#' @return A numeric array with dimensions `(rows, cols, bands)` carrying a
#'   `wavelengths` attribute (`NA` when not declared) and a
#'   `wavelength_evidence` attribute, either `"unavailable"` or
#'   `"caller_declared"`. No wavelength inference is applied.
#' @seealso [tivis_read_cube()]
#' @examples
#' f <- tivis_example_file()
#' cube <- tivis_read_cube_profiled(f)
#' attr(cube, "wavelength_evidence")
#'
#' declared <- tivis_read_cube_profiled(f, wavelengths = seq(500, 535, by = 5))
#' attr(declared, "wavelengths")
#' @export
tivis_read_cube_profiled <- function(path, wavelengths = NULL, bands = NULL) {
  hdr <- tivis_read_header(path)
  if (!is.null(wavelengths) &&
        (!is.numeric(wavelengths) || length(wavelengths) != hdr$bands ||
           any(!is.finite(wavelengths)))) {
    cli::cli_abort(c(
      "Explicit wavelengths must match source bands.",
      "i" = paste(
        "{.arg wavelengths} must be {hdr$bands} finite number{?s},",
        "one per band in the file."
      ),
      "x" = paste(
        "Got {.cls {class(wavelengths)[1]}}",
        "of length {length(wavelengths)}."
      )
    ))
  }
  keep <- if (is.null(bands)) {
    seq_len(hdr$bands)
  } else {
    .check_bands(bands, hdr$bands)
  }
  out <- tivis_read_cube(path, bands = keep)
  attr(out, "wavelengths") <- if (is.null(wavelengths)) {
    rep(NA_real_, length(keep))
  } else {
    wavelengths[keep]
  }
  attr(out, "wavelength_evidence") <- if (is.null(wavelengths)) {
    "unavailable"
  } else {
    "caller_declared"
  }
  out
}
