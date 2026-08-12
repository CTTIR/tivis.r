# Parse a TIVITA Filename Timestamp

TIVITA names every artefact of a recording `YYYY_MM_DD_HH_MM_SS_<what>`.
This extracts the acquisition time from such a name.

## Usage

``` r
tivis_parse_timestamp(x)
```

## Arguments

- x:

  Character vector of file or directory names.

## Value

A `POSIXct` vector, `NA` where no timestamp is present.

## Examples

``` r
tivis_parse_timestamp("2019_11_25_13_29_24_SpecCube.dat")
#> [1] "2019-11-25 13:29:24 UTC"
```
