# Read a TIVITA Cube with Explicit Spectral Evidence

Variant of
[`tivis_read_cube()`](https://cttir.github.io/tivis.r/reference/tivis_read_cube.md)
that does not infer the wavelength axis. The caller either declares the
wavelengths explicitly or the cube is returned with `NA` wavelengths,
and the provenance is recorded in a `wavelength_evidence` attribute.

## Usage

``` r
tivis_read_cube_profiled(path, wavelengths = NULL, bands = NULL)
```

## Arguments

- path:

  Path to a `*_SpecCube.dat` file.

- wavelengths:

  Explicit numeric vector with one wavelength per source band, or `NULL`
  (default) when the wavelengths are unknown.

- bands:

  Optional integer vector of source band indices. `NULL` (default) reads
  every band.

## Value

A numeric array with dimensions `(rows, cols, bands)` carrying a
`wavelengths` attribute (`NA` when not declared) and a
`wavelength_evidence` attribute, either `"unavailable"` or
`"caller_declared"`. No wavelength inference is applied.

## See also

[`tivis_read_cube()`](https://cttir.github.io/tivis.r/reference/tivis_read_cube.md)

## Examples

``` r
f <- tivis_example_file()
cube <- tivis_read_cube_profiled(f)
attr(cube, "wavelength_evidence")
#> [1] "unavailable"

declared <- tivis_read_cube_profiled(f, wavelengths = seq(500, 535, by = 5))
attr(declared, "wavelengths")
#> [1] 500 505 510 515 520 525 530 535
```
