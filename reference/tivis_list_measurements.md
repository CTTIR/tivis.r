# Discover TIVITA Recordings Below a Directory

Walks a directory tree and returns one row per recording found. Only
headers are read, so scanning a large archive is cheap. A file is a
recording when its name ends in `_SpecCube.dat`.

## Usage

``` r
tivis_list_measurements(root, recursive = TRUE)
```

## Arguments

- root:

  Directory to search.

- recursive:

  Logical. Descend into subdirectories. Default `TRUE`.

## Value

A data frame with one row per recording: `path`, `dir`, `timestamp`
(`POSIXct`, see
[`tivis_parse_timestamp()`](https://cttir.github.io/tivis.r/reference/tivis_parse_timestamp.md)),
`width`, `height`, `bands`, `file_size`, and `n_reference_images`. Zero
rows if nothing matches. A cube whose header cannot be decoded is still
listed, with `NA` for `width`, `height`, `bands` and `file_size`.

## Examples

``` r
# Build a tiny archive in a temporary directory from the bundled example
archive <- file.path(tempdir(), "tivita-archive")
dir.create(archive, showWarnings = FALSE)
invisible(file.copy(tivis_example_file(),
                    file.path(archive, "2000_01_01_12_00_00_SpecCube.dat")))
tivis_list_measurements(archive)
#>                                                              path
#> 1 /tmp/RtmpKQDFnh/tivita-archive/2000_01_01_12_00_00_SpecCube.dat
#>                              dir           timestamp width height bands
#> 1 /tmp/RtmpKQDFnh/tivita-archive 2000-01-01 12:00:00    16     12     8
#>   file_size n_reference_images
#> 1      6156                  0
unlink(archive, recursive = TRUE)
```
