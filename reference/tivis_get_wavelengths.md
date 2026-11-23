# TIVITA Wavelength Axis

Returns the nominal wavelength axis this reader assumes for a TIVITA
Tissue recording: band `i` is centred at `500 + 5 * (i - 1)` nm, that is
500-995 nm in 5 nm steps for the native 100 bands.

## Usage

``` r
tivis_get_wavelengths(n_bands = 100L)
```

## Arguments

- n_bands:

  Number of bands, a single positive whole number. Default `100L`, the
  native count.

## Value

Numeric vector of nominal band centre wavelengths in nanometres.

## Details

The cube file stores no wavelengths, so the axis is an assumption of the
reader and is not read from, or checked against, the recording. An
earlier statement that the mapping had been confirmed against the
Suite's RGB export was withdrawn together with that comparison (see
`NEWS.md`). Use
[`tivis_read_cube_profiled()`](https://cttir.github.io/tivis.r/reference/tivis_read_cube_profiled.md)
when the axis must be declared explicitly instead of assumed, for
example for another TIVITA camera model.

## Examples

``` r
range(tivis_get_wavelengths())
#> [1] 500 995
```
