# Read with explicit spectral evidence

Read with explicit spectral evidence

## Usage

``` r
tivis_read_cube_profiled(path, wavelengths = NULL, bands = NULL)
```

## Arguments

- path:

  Cube path.

- wavelengths:

  Explicit full wavelength vector, or NULL for unavailable.

- bands:

  Optional source band indices.

## Value

Native cube with explicit wavelength availability; no wavelength
inference is retained in this additive reader.
