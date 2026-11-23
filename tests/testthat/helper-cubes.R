# Write a cube in TIVITA layout: 12-byte big-endian header, then big-endian
# float32 samples, band-interleaved-by-pixel, pixels column-major.
# `truth` is a (rows, cols, bands) array. `header` overrides the dimensions
# written to the header, to build files that contradict their own header.
write_cube <- function(truth, path, header = NULL) {
  h <- dim(truth)[1]
  w <- dim(truth)[2]
  nb <- dim(truth)[3]
  if (is.null(header)) header <- c(w, h, nb)
  con <- file(path, "wb")
  on.exit(close(con), add = TRUE)
  writeBin(as.integer(header), con, size = 4L, endian = "big")
  # (band, row, col) in column-major order is exactly the file order
  writeBin(as.numeric(aperm(truth, c(3, 1, 2))), con, size = 4L, endian = "big")
  invisible(path)
}

# A cube whose every sample encodes its own coordinates.
coordinate_cube <- function(h, w, nb) {
  truth <- array(0, dim = c(h, w, nb))
  for (y in seq_len(h)) {
    for (x in seq_len(w)) {
      truth[y, x, ] <- y * 100 + x * 10 + seq_len(nb)
    }
  }
  truth
}
