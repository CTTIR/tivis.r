# tivis.r 0.1.0

First release. Pure-R reader for Diaspective Vision TIVITA recordings — no
vendor SDK, no compiled code.

## Features

* `tivis_read_cube()` reads a `*_SpecCube.dat` container and returns a
  `(rows, cols, bands)` array with a `wavelengths` attribute, matching the
  convention used by `hyperspectR::hsi_cube()`. Supports reading a subset of
  bands.
* `tivis_read_header()` decodes the 12-byte dimension header without touching
  the samples, so large archives can be scanned cheaply. It validates the file
  size against the header and errors on a mismatch rather than returning a
  silently recycled array.
* `tivis_get_metadata()` parses the Suite's `*_meta.log`: an INI dialect with
  German section names, `latin1` encoding and comma decimal separators. Values
  are coerced to numerics and logicals where appropriate.
* `tivis_reference_images()` locates the parameter maps the Suite exports
  beside each capture (RGB, oxygenation, NIR perfusion, THI, TWI, OHI).
* `tivis_list_measurements()` walks an archive and returns one row per
  recording.
* `tivis_measurement()` bundles cube, wavelengths, metadata, references and
  timestamp for a single capture.

## Format notes

The container is undocumented by the vendor. The layout implemented here —
big-endian `float32` in band-interleaved-by-pixel order behind three big-endian
`uint32` dimensions, with a 500–995 nm axis in 5 nm steps — was established
empirically and validated against the Suite's own RGB exports across 363
clinical recordings.
