# Read a Complete TIVITA Recording

Convenience wrapper returning the cube together with everything the
Suite stored alongside it: acquisition metadata and the paths of the
exported parameter images.

## Usage

``` r
tivis_measurement(path, bands = NULL)
```

## Arguments

- path:

  Path to a `*_SpecCube.dat` file.

- bands:

  Optional integer vector of band indices. `NULL` reads all.

## Value

A list with `cube`, `wavelengths`, `metadata`, `references`, `timestamp`
and `path`.

## Examples

``` r
m <- tivis_measurement(tivis_example_file())
dim(m$cube)
#> [1] 12 16  8
```
