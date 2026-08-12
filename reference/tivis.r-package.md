# tivis.r: Read Diaspective Vision TIVITA Hyperspectral Recordings

Reads hyperspectral imaging data written by the Diaspective Vision
TIVITA Suite, used for intraoperative tissue and perfusion imaging.
Parses the binary 'SpecCube.dat' container (big-endian float32 samples
in band-interleaved-by-pixel order behind a 12-byte dimension header),
the German-language acquisition metadata log, and the parameter images
the Suite exports alongside each recording (oxygenation, NIR perfusion,
tissue haemoglobin and water indices). Requires no vendor SDK and
contains no compiled code. Companion to 'cuvis.r', which covers Cubert
snapshot cameras, and a data source for 'hyperspectR'.

## See also

Useful links:

- <https://github.com/cttir/tivis.r>

- <https://cttir.github.io/tivis.r/>

- Report bugs at <https://github.com/cttir/tivis.r/issues>

## Author

**Maintainer**: R. Heller <raban.heller@charite.de>
([ORCID](https://orcid.org/0000-0001-8006-9742))

Authors:

- R. Heller <raban.heller@charite.de>
  ([ORCID](https://orcid.org/0000-0001-8006-9742))
