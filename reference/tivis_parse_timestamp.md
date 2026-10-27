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
tivis_parse_timestamp("2000_01_01_12_00_00_SpecCube.dat")
#> [1] "2000-01-01 12:00:00 UTC"
```
