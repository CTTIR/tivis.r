# tivis.r

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21889970.svg)](https://doi.org/10.5281/zenodo.21889970)

<!-- badges: start -->
[![R-CMD-check](https://github.com/CTTIR/tivis.r/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/CTTIR/tivis.r/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

Read hyperspectral recordings written by the **Diaspective Vision TIVITA
Suite**, used for intraoperative tissue and perfusion imaging.

`tivis.r` is the TIVITA counterpart to
[`cuvis.r`](https://github.com/CTTIR/cuvis.r), which covers Cubert snapshot
cameras. The important practical difference: the TIVITA container is a plain
binary format, so **this package needs no vendor SDK and contains no compiled
code**. Install it and it works.

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

TIVITA does not publish a specification, so the format was determined
empirically from reference captures and then **validated against the Suite's
own output**:

| | |
|---|---|
| Header | 12 bytes: three big-endian `uint32` — width, height, bands |
| Samples | big-endian `float32` |
| Layout | band-interleaved-by-pixel (BIP); pixels row-major, x fastest |
| Wavelengths | 500–995 nm in 5 nm steps (100 bands) |
| Values | calibrated reflectance; may fall slightly outside `[0, 1]` |

The layout and wavelength axis were confirmed by correlating each band against
the Suite's own `_RGB-Image.png` export for the same capture. Correlation peaks
at **band 12 = 555 nm (r = 0.86)** — precisely where human photopic luminous
efficiency peaks, which is exactly where a greyscale RGB rendering should agree.
Competing layout hypotheses (band-sequential, transposed axes) score near zero.

Getting this wrong is not a hypothetical: an earlier reader interpreted the
samples as little-endian `uint16` with hard-coded dimensions, and because
`array()` recycles silently it produced full-size cubes of pure noise. Hence
`tivis_read_header()` validates the file size against the header, and the test
suite round-trips a cube whose every sample is uniquely identifiable.

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
