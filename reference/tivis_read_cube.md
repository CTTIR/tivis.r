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

  Optional integer vector of band indices to read, in the order wanted.
  `NULL` (default) reads every band. Selecting a subset still reads
  through the whole file, but keeps only the requested bands in memory.
  Fractional, missing and out-of-range indices are rejected.

- validate:

  Logical. Check that the file size matches the header before reading.
  Default `TRUE`; there is no good reason to disable it. With `FALSE`, a
  file longer than the header implies is read up to the size the header
  describes; a shorter file is still rejected as truncated.

## Value

A numeric array with dimensions `(rows, cols, bands)` — matching the
convention used by `hyperspectR::hsi_cube()` — carrying a `wavelengths`
attribute in nanometres. The wavelengths are the nominal axis from
[`tivis_get_wavelengths()`](https://cttir.github.io/tivis.r/reference/tivis_get_wavelengths.md),
not values stored in the file.

## File format

The vendor publishes no specification. The format was determined
empirically from reference captures, by measuring the periodicity of the
sample stream itself:

- a 12-byte header of three **big-endian** `uint32` values giving
  `width`, `height` and `bands`;

- followed by **big-endian** `float32` samples;

- stored **band-interleaved-by-pixel** (BIP): all bands of one pixel are
  contiguous (the autocorrelation of the raw stream peaks at a lag equal
  to the band count);

- with column-major spatial planes, y varying fastest (the
  autocorrelation of an extracted band plane peaks at a lag equal to the
  image height). Device/export qualification requires an independent
  geometry fixture.

An earlier comparison with the Suite's `_RGB-Image.png` export was
withdrawn as evidence: that image is rotated and rescaled relative to
the cube and cannot serve as pixel-level ground truth (see `NEWS.md`).

Values are calibrated reflectance. They are normally within `[0, 1]` but
may fall slightly below zero or exceed one in specular and saturated
regions, so the reader does not clamp them.

## Memory

Samples are stored as 4-byte floats and returned as 8-byte doubles, so a
native 640 x 480 x 100 cube of 123 MB occupies about 246 MB in R. The
file is read in blocks of image columns, so little working memory is
needed beyond the returned array, and a band subset never holds the
bands it drops.

## See also

[`tivis_read_header()`](https://cttir.github.io/tivis.r/reference/tivis_read_header.md)
for header-only access,
[`tivis_get_wavelengths()`](https://cttir.github.io/tivis.r/reference/tivis_get_wavelengths.md)
for the wavelength axis,
[`tivis_read_cube_profiled()`](https://cttir.github.io/tivis.r/reference/tivis_read_cube_profiled.md)
to read without assuming a wavelength axis.

## Examples

``` r
f <- tivis_example_file()
cube <- tivis_read_cube(f)
dim(cube)
#> [1] 12 16  8
range(attr(cube, "wavelengths"))
#> [1] 500 535
```
