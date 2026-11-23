# Changelog

## tivis.r 0.2.0

### Bug fixes

- [`tivis_measurement()`](https://cttir.github.io/tivis.r/reference/tivis_measurement.md)
  no longer fails for a cube whose name does not end in `_SpecCube.dat`.
  The log path was derived by substitution, so such a cube was parsed as
  its own metadata log and the call aborted on invalid strings. These
  cubes are now read with empty metadata.
- [`tivis_parse_timestamp()`](https://cttir.github.io/tivis.r/reference/tivis_parse_timestamp.md)
  returns `NA` for `NA` input instead of aborting the whole vector, and
  accepts full paths: only the last path component is inspected.
- [`tivis_get_metadata()`](https://cttir.github.io/tivis.r/reference/tivis_get_metadata.md)
  keeps values written in double quotes as strings. Previously the
  content was coerced after the quotes were stripped, so the identifier
  `"0012"` became `12` and the version `"2.0"` became `2`. **Behaviour
  change:** quoted numbers and quoted `TRUE`/`FALSE` are now returned as
  text; unquoted values are converted as before.
- [`tivis_get_metadata()`](https://cttir.github.io/tivis.r/reference/tivis_get_metadata.md)
  reads logs saved as UTF-8 correctly (they were decoded as `latin1` a
  second time), returns all strings in UTF-8, ignores a byte-order mark,
  and returns an empty list for a directory. A binary file, such as the
  cube itself, is rejected with an informative error instead of being
  parsed.
- [`tivis_reference_images()`](https://cttir.github.io/tivis.r/reference/tivis_reference_images.md)
  returns only the images of the given recording when the cube name
  carries a TIVITA timestamp. Recordings sharing one directory used to
  receive each other’s images, which also inflated `n_reference_images`
  in
  [`tivis_list_measurements()`](https://cttir.github.io/tivis.r/reference/tivis_list_measurements.md).
  `.PNG` is matched case-insensitively.
- [`tivis_list_measurements()`](https://cttir.github.io/tivis.r/reference/tivis_list_measurements.md)
  returns its empty result with the same UTC `timestamp` column as a
  populated one.
- [`tivis_read_cube()`](https://cttir.github.io/tivis.r/reference/tivis_read_cube.md)
  rejects fractional band indices such as `2.7` instead of truncating
  them, checks `bands` before reading the samples, and with
  `validate = FALSE` no longer asks for more samples than the file
  holds: a corrupt header could request an arbitrarily large allocation.
- [`tivis_get_wavelengths()`](https://cttir.github.io/tivis.r/reference/tivis_get_wavelengths.md)
  rejects a fractional band count.
- All readers check that the path argument is a single non-missing
  string, and
  [`tivis_read_header()`](https://cttir.github.io/tivis.r/reference/tivis_read_header.md)
  reports a directory as such.

### New features

- [`tivis_parse_timestamp()`](https://cttir.github.io/tivis.r/reference/tivis_parse_timestamp.md)
  gains a `tz` argument (default `"UTC"`, as before) to label the
  wall-clock time in the file name with the time zone of the recording
  site.

### Performance

- [`tivis_read_cube()`](https://cttir.github.io/tivis.r/reference/tivis_read_cube.md)
  reads the file in blocks of image columns instead of loading every
  sample before rearranging them. For a synthetic cube of the native
  size (640 x 480 x 100, 246 MB as an R array) the peak memory of a full
  read fell from about 700 MB to about 365 MB, and that of a three-band
  read from about 265 MB to about 60 MB, at unchanged or slightly better
  speed. A band subset no longer holds the bands it drops.

### Documentation

- The help pages of
  [`tivis_read_cube()`](https://cttir.github.io/tivis.r/reference/tivis_read_cube.md)
  and
  [`tivis_get_wavelengths()`](https://cttir.github.io/tivis.r/reference/tivis_get_wavelengths.md)
  and the vignette no longer state that the layout and the wavelength
  axis were validated against the Suite’s RGB export. That comparison
  had been withdrawn (see the format notes for 0.1.0 below) but was
  still cited. The wavelength axis is now described as what it is: the
  nominal axis assumed by the reader, not stored in the file.
- The vignette gains a figure of the example cube and sections on
  [`tivis_read_cube_profiled()`](https://cttir.github.io/tivis.r/reference/tivis_read_cube_profiled.md)
  and timestamps; the conversion rules of
  [`tivis_get_metadata()`](https://cttir.github.io/tivis.r/reference/tivis_get_metadata.md)
  and the time-zone handling of timestamps are documented.
- The README heads its licence section “Licence”, in line with the
  British English (`Language: en-GB`) of the documentation.

### Packaging

- Prepare the package for CRAN: runnable examples for
  [`tivis_list_measurements()`](https://cttir.github.io/tivis.r/reference/tivis_list_measurements.md)
  and
  [`tivis_reference_images()`](https://cttir.github.io/tivis.r/reference/tivis_reference_images.md)
  that work in a temporary directory, full documentation and examples
  for
  [`tivis_read_cube_profiled()`](https://cttir.github.io/tivis.r/reference/tivis_read_cube_profiled.md),
  and a corrected `\value` for
  [`tivis_available()`](https://cttir.github.io/tivis.r/reference/tivis_available.md).
- Update the maintainer e-mail address to <raban.heller@uni-ulm.de>.
- Declare `Language: en-GB` to match the British spelling used
  throughout and add an `inst/WORDLIST` for the spell check.
- Add `cran-comments.md`.
- Drop the unused `png` package from `Suggests`.
- The README citation, `CITATION.cff` and `.zenodo.json` name the author
  as R. Heller.

## tivis.r 0.1.0

- Standardize the named v5 package logo across README, documentation
  pages and available application headers, with matching light and dark
  artwork.

First release. Pure-R reader for Diaspective Vision TIVITA recordings —
no vendor SDK, no compiled code.

### Features

- [`tivis_read_cube()`](https://cttir.github.io/tivis.r/reference/tivis_read_cube.md)
  reads a `*_SpecCube.dat` container and returns a `(rows, cols, bands)`
  array with a `wavelengths` attribute, matching the convention used by
  `hyperspectR::hsi_cube()`. Supports reading a subset of bands.
- [`tivis_read_header()`](https://cttir.github.io/tivis.r/reference/tivis_read_header.md)
  decodes the 12-byte dimension header without touching the samples, so
  large archives can be scanned cheaply. It validates the file size
  against the header and errors on a mismatch rather than returning a
  silently recycled array.
- [`tivis_get_metadata()`](https://cttir.github.io/tivis.r/reference/tivis_get_metadata.md)
  parses the Suite’s `*_meta.log`: an INI dialect with German section
  names, `latin1` encoding and comma decimal separators. Values are
  coerced to numerics and logicals where appropriate.
- [`tivis_reference_images()`](https://cttir.github.io/tivis.r/reference/tivis_reference_images.md)
  locates the parameter maps the Suite exports beside each capture (RGB,
  oxygenation, NIR perfusion, THI, TWI, OHI).
- [`tivis_list_measurements()`](https://cttir.github.io/tivis.r/reference/tivis_list_measurements.md)
  walks an archive and returns one row per recording.
- [`tivis_measurement()`](https://cttir.github.io/tivis.r/reference/tivis_measurement.md)
  bundles cube, wavelengths, metadata, references and timestamp for a
  single capture.

### Format notes

The container is undocumented by the vendor. The layout implemented here
— big-endian `float32`, band-interleaved-by-pixel, pixels
**column-major** with y varying fastest, behind three big-endian
`uint32` dimensions, on a 500–995 nm axis in 5 nm steps — was
established by measuring the sample stream’s own periodicity.

Autocorrelation of the raw stream peaks at lag 100 (r = 0.95), the band
count, with harmonics at 200/300/400: band interleaving by pixel.
Autocorrelation of an extracted band plane peaks at lag 480 (r = 0.99),
the image height, versus r = 0.43 at lag 640, the width: pixels run down
columns.

During development this was briefly documented as row-major on the
strength of a correlation against the Suite’s RGB export. That was
incorrect — the comparison was made on downsampled images, where the
tiling artefact it should have exposed was averaged away. The vendor PNG
is rotated and rescaled relative to the cube and is not usable as
pixel-level ground truth.
