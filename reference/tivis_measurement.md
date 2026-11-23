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

A plain list with

- `cube`: the array returned by
  [`tivis_read_cube()`](https://cttir.github.io/tivis.r/reference/tivis_read_cube.md);

- `wavelengths`: its wavelength axis in nanometres;

- `metadata`: the result of
  [`tivis_get_metadata()`](https://cttir.github.io/tivis.r/reference/tivis_get_metadata.md),
  an empty list when no log is found;

- `references`: the result of
  [`tivis_reference_images()`](https://cttir.github.io/tivis.r/reference/tivis_reference_images.md);

- `timestamp`: the result of
  [`tivis_parse_timestamp()`](https://cttir.github.io/tivis.r/reference/tivis_parse_timestamp.md);

- `path`: the input path.

## Details

The acquisition log is looked up beside the cube by replacing the
`_SpecCube.dat` suffix with `_meta.log`. A cube that does not follow
this naming scheme is read without metadata.

## Examples

``` r
m <- tivis_measurement(tivis_example_file())
dim(m$cube)
#> [1] 12 16  8
m$metadata$Camera$Exposure
#> [1] 90
```
