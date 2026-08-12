# Read TIVITA Acquisition Metadata

Parses a `*_meta.log` file written beside a TIVITA recording. The Suite
writes an INI-style file with German section and key names, `latin1`
encoding and comma decimal separators; all three are handled here.

## Usage

``` r
tivis_get_metadata(path)
```

## Arguments

- path:

  Path to a `*_meta.log` file.

## Value

A named list of sections, each a named list of entries. Returns an empty
list if the file does not exist.

## Details

Numeric-looking values are converted to numbers (`"7,000000"` becomes
`7`), `TRUE`/`FALSE` become logicals, and surrounding quotes are
stripped. Unrecognised values are returned as trimmed strings.

## Examples

``` r
log_file <- system.file("extdata", "example_meta.log", package = "tivis.r")
if (nzchar(log_file)) str(tivis_get_metadata(log_file))
#> List of 4
#>  $ Camera             :List of 5
#>   ..$ CamID         : chr "0000-00000"
#>   ..$ Exposure      : num 90
#>   ..$ analoger Gain : num 8
#>   ..$ digitaler Gain: num 32
#>   ..$ Speed         : num 950
#>  $ SW                 :List of 2
#>   ..$ Name   : chr "TIVITA® Suite"
#>   ..$ Version: chr "1.6.0.1"
#>  $ Fremdlichterkennung:List of 3
#>   ..$ Fremdlicht erkannt?: logi FALSE
#>   ..$ PixelmitFremdlicht : num 0
#>   ..$ Intensity Grenzwert: num 7
#>  $ Aufnahme           :List of 1
#>   ..$ Aufnahmemodus: chr "Reflektanz"
```
