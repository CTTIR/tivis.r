# Locate the Parameter Images Beside a Recording

The TIVITA Suite exports its computed parameter maps as PNGs next to
each cube: an RGB rendering plus tissue indices. These are the Suite's
own results and are useful as a reference when validating independently
computed indices.

## Usage

``` r
tivis_reference_images(path)
```

## Arguments

- path:

  Path to a `*_SpecCube.dat` file, or to the directory holding it.

## Value

A named character vector of existing file paths. Names are the parameter
identifiers used by the Suite, for example `RGB-Image`, `Oxygenation`,
`NIR-Perfusion`, `THI`, `TWI`, `OHI`. Zero-length if none are present.

## Examples

``` r
# \donttest{
# tivis_reference_images("/path/to/2019_11_25_13_29_24_SpecCube.dat")
# }
```
