# Package index

## Reading

Parse the binary SpecCube container. Headers are cheap to read, so an
archive can be surveyed without touching the samples.

- [`tivis_read_cube()`](https://cttir.github.io/tivis.r/reference/tivis_read_cube.md)
  : Read a TIVITA Suite Hyperspectral Cube
- [`tivis_read_header()`](https://cttir.github.io/tivis.r/reference/tivis_read_header.md)
  : Read a TIVITA Cube Header
- [`tivis_get_wavelengths()`](https://cttir.github.io/tivis.r/reference/tivis_get_wavelengths.md)
  : TIVITA Wavelength Axis

## Recordings

A TIVITA capture is a directory: the cube, an acquisition log, and the
parameter images the Suite exported alongside it.

- [`tivis_measurement()`](https://cttir.github.io/tivis.r/reference/tivis_measurement.md)
  : Read a Complete TIVITA Recording
- [`tivis_list_measurements()`](https://cttir.github.io/tivis.r/reference/tivis_list_measurements.md)
  : Discover TIVITA Recordings Below a Directory
- [`tivis_get_metadata()`](https://cttir.github.io/tivis.r/reference/tivis_get_metadata.md)
  : Read TIVITA Acquisition Metadata
- [`tivis_reference_images()`](https://cttir.github.io/tivis.r/reference/tivis_reference_images.md)
  : Locate the Parameter Images Beside a Recording
- [`tivis_parse_timestamp()`](https://cttir.github.io/tivis.r/reference/tivis_parse_timestamp.md)
  : Parse a TIVITA Filename Timestamp

## Package

- [`tivis_available()`](https://cttir.github.io/tivis.r/reference/tivis_available.md)
  : Is the TIVITA Reader Available?
- [`tivis_example_file()`](https://cttir.github.io/tivis.r/reference/tivis_example_file.md)
  : Path to the Bundled Example Cube
- [`tivis.r`](https://cttir.github.io/tivis.r/reference/tivis.r-package.md)
  [`tivis.r-package`](https://cttir.github.io/tivis.r/reference/tivis.r-package.md)
  : tivis.r: Read Diaspective Vision TIVITA Hyperspectral Recordings
