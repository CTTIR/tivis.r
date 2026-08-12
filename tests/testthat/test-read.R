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
  # pixels are stored column-major: y varies fastest
  flat <- numeric(w * h * nb)
  i <- 1L
  for (x in seq_len(w)) for (y in seq_len(h)) {
    flat[i:(i + nb - 1L)] <- truth[y, x, ]
    i <- i + nb
  }
  writeBin(flat, con, size = 4L, endian = "big")
  close(con)

  expect_equal(tivis_read_cube(tmp), truth, ignore_attr = TRUE)
})

test_that("a single bright pixel lands at the coordinate it was written to", {
  # This pins the x/y mapping against an asymmetric, hand-placed feature.
  # The round-trip test above cannot catch a transposed or tiled reader,
  # because it checks the writer against the reader; both were wrong together
  # in an earlier version, and the suite stayed green while band images came
  # out tiled four times across.
  w <- 7L; h <- 5L; nb <- 3L
  target_y <- 2L; target_x <- 6L

  tmp <- tempfile(fileext = "_SpecCube.dat")
  on.exit(unlink(tmp), add = TRUE)
  con <- file(tmp, "wb")
  writeBin(as.integer(c(w, h, nb)), con, size = 4L, endian = "big")
  flat <- numeric(w * h * nb)
  i <- 1L
  for (x in seq_len(w)) for (y in seq_len(h)) {
    flat[i:(i + nb - 1L)] <- if (y == target_y && x == target_x) 1 else 0
    i <- i + nb
  }
  writeBin(flat, con, size = 4L, endian = "big")
  close(con)

  cube <- tivis_read_cube(tmp)
  expect_equal(dim(cube), c(h, w, nb))
  expect_equal(cube[target_y, target_x, 1], 1)
  expect_equal(sum(cube[, , 1]), 1)          # nothing smeared elsewhere
  expect_equal(which(cube[, , 1] == 1, arr.ind = TRUE)[1, ],
               c(row = target_y, col = target_x))
})

test_that("an asymmetric ramp is not transposed", {
  # Complements the single-pixel test: a gradient that differs along x and y
  # pins the orientation even if a future change preserves point positions.
  w <- 9L; h <- 4L; nb <- 2L
  truth <- array(0, dim = c(h, w, nb))
  for (y in seq_len(h)) for (x in seq_len(w)) truth[y, x, ] <- 10 * y + x

  tmp <- tempfile(fileext = "_SpecCube.dat")
  on.exit(unlink(tmp), add = TRUE)
  con <- file(tmp, "wb")
  writeBin(as.integer(c(w, h, nb)), con, size = 4L, endian = "big")
  flat <- numeric(w * h * nb); i <- 1L
  for (x in seq_len(w)) for (y in seq_len(h)) {
    flat[i:(i + nb - 1L)] <- truth[y, x, ]; i <- i + nb
  }
  writeBin(flat, con, size = 4L, endian = "big")
  close(con)

  got <- tivis_read_cube(tmp)[, , 1]
  expect_equal(got, truth[, , 1], ignore_attr = TRUE)
  # rows must increase by 10, columns by 1 -- not the other way round
  expect_equal(unname(got[2, 1] - got[1, 1]), 10)
  expect_equal(unname(got[1, 2] - got[1, 1]), 1)
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
