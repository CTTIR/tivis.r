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

## Known limitation: spatial layout

The container is undocumented by the vendor. The header, sample type
(big-endian `float32`) and wavelength axis (500–995 nm in 5 nm steps) are
settled. **The ordering of samples within a band is not.**

`tivis_read_cube()` currently assumes band-interleaved-by-pixel ordering, which
produces band images tiled four times horizontally and heavily striped. Do not
use the returned images for analysis until this is resolved.

An earlier draft of this file claimed the layout had been validated against the
vendor's RGB exports at `r = 0.86`. That measurement was taken on downsampled
images, and the reference is dominated by horizontal structure that survives
horizontal tiling, so a wrong layout scored well. At full resolution — and on
visual inspection — it is clearly incorrect.
