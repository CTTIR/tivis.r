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
# Mimic a TIVITA export directory in a temporary location
rec <- file.path(tempdir(), "tivita-recording")
dir.create(rec, showWarnings = FALSE)
cube <- file.path(rec, "2000_01_01_12_00_00_SpecCube.dat")
invisible(file.copy(tivis_example_file(), cube))
invisible(file.create(file.path(rec, "2000_01_01_12_00_00_Oxygenation.png")))
tivis_reference_images(cube)
#>                                                            Oxygenation 
#> "/tmp/Rtmpjg55Mj/tivita-recording/2000_01_01_12_00_00_Oxygenation.png" 
unlink(rec, recursive = TRUE)
```
