## Generate the bundled example recording.
##
## Writes a small cube in the genuine TIVITA container layout so that examples,
## tests and vignettes exercise the real parser without shipping any clinical
## data. Run with: Rscript data-raw/make-fixture.R

set.seed(42)

width  <- 16L
height <- 12L
bands  <- 8L

wl <- 500 + 5 * (seq_len(bands) - 1L)

## A smooth spatial gradient with a bright disc, modulated per band by a
## plausible tissue-like spectrum, so filters and indices show real structure
## rather than noise.
xs <- matrix(rep(seq_len(width), each = height), nrow = height)
ys <- matrix(rep(seq_len(height), times = width), nrow = height)
disc <- ((xs - width / 2)^2 + (ys - height / 2)^2) < (min(width, height) / 3)^2

spectrum <- 0.35 + 0.25 * sin(seq_len(bands) / bands * pi)

cube <- array(0.0, dim = c(height, width, bands))
for (b in seq_len(bands)) {
  base <- 0.20 + 0.30 * (xs / width) + 0.15 * (ys / height)
  cube[, , b] <- base * spectrum[b] + ifelse(disc, 0.18, 0) +
    stats::rnorm(width * height, sd = 0.005)
}

## Serialise: 12-byte big-endian uint32 header (width, height, bands),
## then big-endian float32 samples band-interleaved-by-pixel, pixels
## row-major with x varying fastest.
out <- file.path("inst", "extdata", "example_SpecCube.dat")
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)

con <- file(out, "wb")
writeBin(as.integer(c(width, height, bands)), con, size = 4L, endian = "big")

interleaved <- numeric(width * height * bands)
i <- 1L
for (y in seq_len(height)) {
  for (x in seq_len(width)) {
    interleaved[i:(i + bands - 1L)] <- cube[y, x, ]
    i <- i + bands
  }
}
writeBin(interleaved, con, size = 4L, endian = "big")
close(con)

cat("wrote", out, "-", file.size(out), "bytes\n")
cat("expected:", 12 + width * height * bands * 4, "bytes\n")

## A metadata log mirroring the TIVITA Suite's German INI dialect, including a
## comma decimal separator and a latin1 registered-trademark sign.
log_path <- file.path("inst", "extdata", "example_meta.log")
log_lines <- c(
  "[Camera]",
  'CamID = "0000-00000"',
  "Exposure = 90",
  "analoger Gain = 8",
  "digitaler Gain = 32",
  "Speed = 950",
  "",
  "[SW]",
  'Name = "TIVITA\xae Suite"',
  'Version = "1.6.0.1"',
  "",
  "[Fremdlichterkennung]",
  "Fremdlicht erkannt? = FALSE",
  "PixelmitFremdlicht = 0",
  "Intensity Grenzwert = 7,000000",
  "",
  "[Aufnahme]",
  'Aufnahmemodus = "Reflektanz"'
)
con <- file(log_path, "wb")
writeLines(log_lines, con, useBytes = TRUE)
close(con)
cat("wrote", log_path, "\n")
