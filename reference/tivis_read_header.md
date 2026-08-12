# Read a TIVITA Cube Header

Parses the 12-byte header of a `*_SpecCube.dat` file without reading the
sample data, which makes it cheap enough to scan large archives.

## Usage

``` r
tivis_read_header(path, validate = TRUE)
```

## Arguments

- path:

  Path to a `*_SpecCube.dat` file.

- validate:

  Logical. Verify that the file size equals
  `12 + width * height * bands * 4`. Default `TRUE`.

## Value

A named list with `width`, `height`, `bands`, `n_values` and
`file_size`.

## Examples

``` r
tivis_read_header(tivis_example_file())
#> $width
#> [1] 16
#> 
#> $height
#> [1] 12
#> 
#> $bands
#> [1] 8
#> 
#> $n_values
#> [1] 1536
#> 
#> $file_size
#> [1] 6156
#> 
```
