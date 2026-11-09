# Discover TIVITA Recordings Below a Directory

Walks a directory tree and returns one row per recording found. Only
headers are read, so scanning a large archive is cheap.

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

A data frame with one row per recording: `path`, `dir`, `timestamp`,
`width`, `height`, `bands`, `file_size`, and `n_reference_images`. Zero
rows if nothing matches.

## Examples

``` r
# Build a tiny archive in a temporary directory from the bundled example
archive <- file.path(tempdir(), "tivita-archive")
dir.create(archive, showWarnings = FALSE)
invisible(file.copy(tivis_example_file(),
                    file.path(archive, "2000_01_01_12_00_00_SpecCube.dat")))
tivis_list_measurements(archive)
#>                                                              path
#> 1 /tmp/Rtmpjg55Mj/tivita-archive/2000_01_01_12_00_00_SpecCube.dat
#>                              dir           timestamp width height bands
#> 1 /tmp/Rtmpjg55Mj/tivita-archive 2000-01-01 12:00:00    16     12     8
#>   file_size n_reference_images
#> 1      6156                  0
unlink(archive, recursive = TRUE)
```
