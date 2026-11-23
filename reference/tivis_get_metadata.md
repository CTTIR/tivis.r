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
list if the file does not exist. A binary file, such as the cube itself,
is rejected with an error.

## Details

Values are converted as follows:

- a value in double quotes is a string. The quotes are stripped and the
  content is returned verbatim, so identifiers and version strings such
  as `"0012"` or `"2.0"` keep their leading and trailing zeros;

- an unquoted number becomes a numeric, with a decimal comma or a
  decimal point (`7,000000` becomes `7`);

- an unquoted `TRUE` or `FALSE` (in any case) becomes a logical;

- anything else is returned as a trimmed string.

Strings are returned in UTF-8. A file that is already valid UTF-8 is
read as such; any other file is taken to be `latin1`. Lines starting
with `;` or `#` are comments. Entries before the first section header
are collected in a section named `general`. If a key occurs twice in a
section, the last value wins.

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
