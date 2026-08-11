# tivis.r

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21889970.svg)](https://doi.org/10.5281/zenodo.21889970)

<!-- badges: start -->
[![R-CMD-check](https://github.com/CTTIR/tivis.r/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/CTTIR/tivis.r/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

> [!WARNING]
> **The spatial layout is not yet correct.** `tivis_read_cube()` currently
> returns band images that are tiled horizontally and striped — the header,
> sample type and wavelength axis are settled, but the ordering of samples
> within a band is not. Do not use the returned images for analysis yet.
> See [The file format](#the-file-format).

Read hyperspectral recordings written by the **Diaspective Vision TIVITA
Suite**, used for intraoperative tissue and perfusion imaging.

`tivis.r` is the TIVITA counterpart to
[`cuvis.r`](https://github.com/CTTIR/cuvis.r), which covers Cubert snapshot
cameras. The important practical difference: the TIVITA container is a plain
binary format, so **this package needs no vendor SDK and contains no compiled
code** — nothing to install beyond R itself.

Both packages feed [`hyperspectR`](https://github.com/CTTIR/hyperspectR), which
owns the `hsi_cube` class and the analysis pipeline.

## Installation

```r
# install.packages("remotes")
remotes::install_github("CTTIR/tivis.r")
```

## Usage

```r
library(tivis.r)

# Inspect a recording's geometry without reading 123 MB of samples
tivis_read_header("2019_11_25_13_29_24_SpecCube.dat")
#> $width  [1] 640
#> $height [1] 480
#> $bands  [1] 100

# Read the cube: (rows, cols, bands), with wavelengths attached
cube <- tivis_read_cube("2019_11_25_13_29_24_SpecCube.dat")
dim(cube)
#> [1] 480 640 100

# Everything the Suite stored for one capture
m <- tivis_measurement("2019_11_25_13_29_24_SpecCube.dat")
m$metadata$Camera$Exposure
names(m$references)
#> "NIR-Perfusion" "Oxygenation" "RGB-Image" "THI" "TWI"

# Scan an archive cheaply (headers only)
tivis_list_measurements("/archive/tivita")
```

## The file format

TIVITA does not publish a specification, so the format is being determined
empirically. Part of it is settled; part is not.

**Settled:**

| | |
|---|---|
| Header | 12 bytes: three big-endian `uint32` — width, height, bands |
| Samples | big-endian `float32` |
| Wavelengths | 500–995 nm in 5 nm steps (100 bands) |
| Values | calibrated reflectance; may fall slightly outside `[0, 1]` |

The header decodes to `640, 480, 100` and the file size equals
`12 + 640 × 480 × 100 × 4` exactly. Big-endian `float32` yields physically
plausible reflectance with no non-finite values, where little-endian yields
thousands of `NaN`. The wavelength axis is corroborated independently.

**Not settled — the sample ordering within a band.** Reading the samples
band-interleaved-by-pixel produces an image that is *tiled four times
horizontally and heavily striped*, so it is wrong. Band-sequential and
band-interleaved-by-line orderings are worse. De-interleaving columns in four
groups removes the tiling and yields a continuous image, but that image still
does not match the Suite's own `_RGB-Image.png` for the same capture, so it is
not right either.

A caution about how this was previously assessed: an earlier version of this
README claimed the layout was validated at `r = 0.86` against the vendor RGB
export. That figure was obtained by correlating **downsampled** images, and the
reference happens to be dominated by horizontal structure that survives
horizontal tiling — so a visibly tiled image still scored highly. Scored at
full resolution, and simply *looked at*, the layout is plainly wrong. The
lesson is that a summary statistic was trusted where an image should have been
inspected.

Getting this wrong is easy to miss: `array()` recycles silently, so a reader
with the wrong ordering still returns a full-size, plausible-looking cube.
`tivis_read_header()` therefore validates the file size against the header, and
the test suite round-trips a cube whose every sample is uniquely identifiable —
that round-trip passes, because it tests the writer and reader against each
other rather than against reality.

## Related packages

| Package | Role |
|---|---|
| [`cuvis.r`](https://github.com/CTTIR/cuvis.r) | Cubert `.cu3s` via the CUVIS SDK |
| [`hyperspectR`](https://github.com/CTTIR/hyperspectR) | `hsi_cube` class, preprocessing, tissue indices |
| [`hyperspectaculR`](https://github.com/CTTIR/hyperspectaculR) | Publication-grade visualisation |

## License

MIT

## Citation

If you use this software, please cite it as:

> Heller, R. (2026). *tivis.r: Reading Diaspective Vision TIVITA hyperspectral recordings* (Version 0.1.0) [Computer software]. Zenodo. https://doi.org/10.5281/zenodo.21889970

DOI: [10.5281/zenodo.21889970](https://doi.org/10.5281/zenodo.21889970)
