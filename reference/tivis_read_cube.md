# Read a TIVITA Suite Hyperspectral Cube

Reads a `*_SpecCube.dat` file written by the Diaspective Vision TIVITA
Suite. Unlike Cubert `.cu3s` session files, the TIVITA container is a
plain binary format, so this package needs no vendor SDK and no compiled
code.

## Usage

``` r
tivis_read_cube(path, bands = NULL, validate = TRUE)
```

## Arguments

- path:

  Path to a `*_SpecCube.dat` file.

- bands:

  Optional integer vector of band indices to read. `NULL` (default)
  reads every band. Selecting a subset still reads the whole file, but
  returns only the requested bands.

- validate:

  Logical. Check that the file size matches the header before reading.
  Default `TRUE`; there is no good reason to disable it.

## Value

A numeric array with dimensions `(rows, cols, bands)` — matching the
convention used by `hyperspectR::hsi_cube()` — carrying a `wavelengths`
attribute in nanometres.

## File format

The format was determined empirically from reference captures and
validated against the TIVITA Suite's own `_RGB-Image.png` exports:

- a 12-byte header of three **big-endian** `uint32` values giving
  `width`, `height` and `bands`;

- followed by **big-endian** `float32` samples;

- stored **band-interleaved-by-pixel** (BIP): all bands of one pixel are
  contiguous, pixels run in row-major order (x varies fastest).

Values are calibrated reflectance. They are normally within `[0, 1]` but
may fall slightly below zero or exceed one in specular and saturated
regions, so the reader does not clamp them.

## See also

[`tivis_read_header()`](https://cttir.github.io/tivis.r/reference/tivis_read_header.md)
for header-only access,
[`tivis_get_wavelengths()`](https://cttir.github.io/tivis.r/reference/tivis_get_wavelengths.md)
for the wavelength axis.

## Examples

``` r
f <- tivis_example_file()
cube <- tivis_read_cube(f)
dim(cube)
#> [1] 12 16  8
range(attr(cube, "wavelengths"))
#> [1] 500 535
```
