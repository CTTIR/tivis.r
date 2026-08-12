# Changelog

## tivis.r 0.1.0

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
