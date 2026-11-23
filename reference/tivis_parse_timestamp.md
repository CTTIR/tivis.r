# Parse a TIVITA Filename Timestamp

TIVITA names every artefact of a recording `YYYY_MM_DD_HH_MM_SS_<what>`.
This extracts the acquisition time from such a name.

## Usage

``` r
tivis_parse_timestamp(x, tz = "UTC")
```

## Arguments

- x:

  Character vector of file or directory names. Full paths are accepted;
  only the last path component is inspected.

- tz:

  Time zone used to label the parsed wall-clock time. Default `"UTC"`.

## Value

A `POSIXct` vector of the same length as `x`, `NA` where no valid
timestamp is present (including `NA` input).

## Details

The file name records the wall-clock time of the acquisition computer
and carries no time-zone information. The digits are therefore taken as
they are and labelled with `tz`; no conversion takes place. Pass the
time zone of the recording site if the result is compared with other
clocks. A wall-clock time that does not exist in `tz`, such as one
inside the hour skipped at the start of daylight-saving time, cannot be
represented and may come back as `NA`; the default `"UTC"` has no such
gaps.

## Examples

``` r
tivis_parse_timestamp("2000_01_01_12_00_00_SpecCube.dat")
#> [1] "2000-01-01 12:00:00 UTC"

# full paths work, and names without a timestamp give NA
tivis_parse_timestamp(c("/archive/2000_01_01_12_00_00_SpecCube.dat",
                        "notes.txt"))
#> [1] "2000-01-01 12:00:00 UTC" NA                       

# label the wall-clock time with the recording site's time zone
tivis_parse_timestamp("2000_01_01_12_00_00_SpecCube.dat",
                      tz = "Europe/Berlin")
#> [1] "2000-01-01 12:00:00 CET"
```
