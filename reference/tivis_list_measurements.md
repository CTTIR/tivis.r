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
# \donttest{
# tivis_list_measurements("/archive/tivita")
# }
```
