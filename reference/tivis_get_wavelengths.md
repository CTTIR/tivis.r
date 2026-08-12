# TIVITA Wavelength Axis

The TIVITA Tissue camera samples 500-995 nm in 5 nm steps. The mapping
was confirmed empirically: correlating each band against the TIVITA
Suite's own greyscale RGB export peaks at band 12, i.e. 555 nm, which is
where human photopic luminous efficiency peaks.

## Usage

``` r
tivis_get_wavelengths(n_bands = 100L)
```

## Arguments

- n_bands:

  Integer number of bands. Default `100L`, the native count.

## Value

Numeric vector of band centre wavelengths in nanometres.

## Examples

``` r
range(tivis_get_wavelengths())
#> [1] 500 995
```
