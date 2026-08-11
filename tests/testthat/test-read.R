test_that("header decodes the bundled example", {
  h <- tivis_read_header(tivis_example_file())
  expect_equal(h$width, 16L)
  expect_equal(h$height, 12L)
  expect_equal(h$bands, 8L)
  expect_equal(h$file_size, 12 + 16 * 12 * 8 * 4)
})

test_that("cube is returned as (rows, cols, bands)", {
  cube <- tivis_read_cube(tivis_example_file())
  # header is (width, height, bands) but the array follows hsi_cube's
  # (rows, cols, bands) convention, so height comes first.
  expect_equal(dim(cube), c(12L, 16L, 8L))
  expect_type(cube, "double")
  expect_true(all(is.finite(cube)))
})

test_that("wavelengths follow the 500 nm / 5 nm grid", {
  expect_equal(tivis_get_wavelengths(8L), c(500, 505, 510, 515, 520, 525, 530, 535))
  expect_equal(range(tivis_get_wavelengths(100L)), c(500, 995))
  expect_length(tivis_get_wavelengths(100L), 100L)
  expect_equal(attr(tivis_read_cube(tivis_example_file()), "wavelengths"),
               tivis_get_wavelengths(8L))
  expect_error(tivis_get_wavelengths(0), "positive integer")
})

test_that("band subsetting returns exactly the requested bands", {
  f <- tivis_example_file()
  full <- tivis_read_cube(f)
  sub <- tivis_read_cube(f, bands = c(2L, 5L))

  expect_equal(dim(sub), c(12L, 16L, 2L))
  expect_equal(sub[, , 1], full[, , 2])
  expect_equal(sub[, , 2], full[, , 5])
  expect_equal(attr(sub, "wavelengths"), tivis_get_wavelengths(8L)[c(2, 5)])
})

test_that("out-of-range bands are rejected rather than silently recycled", {
  f <- tivis_example_file()
  expect_error(tivis_read_cube(f, bands = 99L), "out of range")
  expect_error(tivis_read_cube(f, bands = 0L), "out of range")
})

test_that("the BIP layout round-trips a known cube", {
  # Write a cube whose every sample is uniquely identifiable, so any
  # transposition or interleave error shows up as a mismatch rather than as
  # plausible-looking noise. This is the check the original TIVITA reader
  # lacked: array() silently recycles, so a wrong layout produced garbage
  # that still had the right shape.
  w <- 5L; h <- 3L; nb <- 4L
  truth <- array(0, dim = c(h, w, nb))
  for (y in seq_len(h)) for (x in seq_len(w)) for (b in seq_len(nb)) {
    truth[y, x, b] <- y * 100 + x * 10 + b
  }

  tmp <- tempfile(fileext = "_SpecCube.dat")
  on.exit(unlink(tmp), add = TRUE)
  con <- file(tmp, "wb")
  writeBin(as.integer(c(w, h, nb)), con, size = 4L, endian = "big")
  flat <- numeric(w * h * nb)
  i <- 1L
  for (y in seq_len(h)) for (x in seq_len(w)) {
    flat[i:(i + nb - 1L)] <- truth[y, x, ]
    i <- i + nb
  }
  writeBin(flat, con, size = 4L, endian = "big")
  close(con)

  expect_equal(tivis_read_cube(tmp), truth, ignore_attr = TRUE)
})

test_that("malformed files are rejected with a useful message", {
  expect_error(tivis_read_header(tempfile()), "File not found")

  # header promises more data than the file holds
  tmp <- tempfile(fileext = ".dat")
  on.exit(unlink(tmp), add = TRUE)
  con <- file(tmp, "wb")
  writeBin(as.integer(c(640L, 480L, 100L)), con, size = 4L, endian = "big")
  writeBin(numeric(10), con, size = 4L, endian = "big")
  close(con)
  expect_error(tivis_read_header(tmp), "does not describe")

  # first 12 bytes are not three positive integers
  bad <- tempfile(fileext = ".dat")
  on.exit(unlink(bad), add = TRUE)
  writeBin(raw(64), bad)
  expect_error(tivis_read_header(bad), "Not a readable TIVITA cube")
})

test_that("tivis_available reports pure-R availability", {
  expect_true(tivis_available())
})
