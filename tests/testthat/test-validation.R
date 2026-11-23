test_that("path arguments must be one non-missing string", {
  expect_error(tivis_read_header(c("a", "b")), "single path")
  expect_error(tivis_read_header(NA_character_), "single path")
  expect_error(tivis_read_header(1), "single path")
  expect_error(tivis_read_header(""), "single path")
  expect_error(tivis_read_cube(character(0)), "single path")
})

test_that("a directory is not accepted as a cube", {
  dir <- withr::local_tempdir()
  expect_error(tivis_read_header(dir), "is a directory")
  expect_error(tivis_read_cube(dir), "is a directory")
})

test_that("fractional and missing band indices are rejected", {
  f <- tivis_example_file()
  # as.integer() would truncate 2.7 to band 2 without a word
  expect_error(tivis_read_cube(f, bands = 2.7), "whole-number")
  expect_error(tivis_read_cube(f, bands = c(1, NA)), "whole-number")
  expect_error(tivis_read_cube(f, bands = "a"), "whole-number")
  expect_error(tivis_read_cube(f, bands = Inf), "whole-number")
  expect_error(tivis_read_cube_profiled(f, bands = 1.5), "whole-number")
  # whole numbers stored as doubles are fine, and the order is kept
  expect_no_warning(sub <- tivis_read_cube(f, bands = c(3, 1)))
  expect_equal(attr(sub, "wavelengths"), c(510, 500))
  expect_equal(sub[, , 2], tivis_read_cube(f)[, , 1])
})

test_that("a band selection is checked before the samples are read", {
  # header alone, no samples: only the band check can fail first
  tmp <- withr::local_tempfile(fileext = "_SpecCube.dat")
  write_cube(coordinate_cube(2, 2, 2), tmp)
  expect_error(tivis_read_cube(tmp, bands = 3L), "out of range")
  expect_error(tivis_read_cube(tmp, bands = 3L), "2 bands")
})

test_that("the band count must be a positive whole number", {
  expect_error(tivis_get_wavelengths(2.5), "positive integer")
  expect_error(tivis_get_wavelengths(-1), "positive integer")
  expect_error(tivis_get_wavelengths(NA), "positive integer")
  expect_error(tivis_get_wavelengths(c(1, 2)), "positive integer")
  expect_error(tivis_get_wavelengths(NULL), "positive integer")
  expect_no_warning(expect_error(tivis_get_wavelengths("x"), "positive"))
  expect_equal(tivis_get_wavelengths(1), 500)
  expect_equal(tivis_get_wavelengths(3), c(500, 505, 510))
})

test_that("a truncated cube is rejected even without header validation", {
  tmp <- withr::local_tempfile(fileext = "_SpecCube.dat")
  # header promises 3 x 2 x 2 = 12 samples, the file holds 8
  write_cube(coordinate_cube(2, 2, 2), tmp, header = c(3L, 2L, 2L))
  expect_error(tivis_read_cube(tmp), "does not describe")
  expect_error(tivis_read_cube(tmp, validate = FALSE), "Truncated cube")
  expect_error(tivis_read_cube(tmp, validate = FALSE), "holds 8")
})

test_that("a corrupt header cannot trigger a huge allocation", {
  tmp <- withr::local_tempfile(fileext = "_SpecCube.dat")
  # 30000^3 float32 samples would need about 2e14 bytes as doubles; the
  # reader must compare against the file size instead of asking readBin()
  write_cube(coordinate_cube(2, 2, 2), tmp, header = rep(30000L, 3))
  expect_error(tivis_read_cube(tmp, validate = FALSE), "Truncated cube")
  expect_equal(tivis_read_header(tmp, validate = FALSE)$n_values, 2.7e13)
})

test_that("without validation a longer file is read up to the header size", {
  tmp <- withr::local_tempfile(fileext = "_SpecCube.dat")
  truth <- coordinate_cube(3, 4, 2)
  write_cube(truth, tmp)
  con <- file(tmp, "ab")
  writeBin(numeric(5), con, size = 4L, endian = "big")
  close(con)

  expect_error(tivis_read_cube(tmp), "does not describe")
  expect_equal(tivis_read_cube(tmp, validate = FALSE), truth,
               ignore_attr = TRUE)
})

test_that("a file shorter than its header is not a cube", {
  tmp <- withr::local_tempfile(fileext = ".dat")
  writeBin(as.raw(1:5), tmp)
  expect_error(tivis_read_header(tmp), "Not a readable TIVITA cube")
  file.create(tmp)
  expect_error(tivis_read_header(tmp), "Not a readable TIVITA cube")
})

test_that("negative header dimensions are rejected", {
  tmp <- withr::local_tempfile(fileext = ".dat")
  write_cube(coordinate_cube(2, 2, 2), tmp, header = c(-2L, 2L, 2L))
  expect_error(tivis_read_header(tmp, validate = FALSE), "Not a readable")
})

test_that("a single-pixel, single-band cube keeps three dimensions", {
  tmp <- withr::local_tempfile(fileext = "_SpecCube.dat")
  write_cube(array(0.25, dim = c(1, 1, 1)), tmp)
  cube <- tivis_read_cube(tmp)
  expect_equal(dim(cube), c(1L, 1L, 1L))
  expect_equal(cube[1, 1, 1], 0.25)
  expect_equal(attr(cube, "wavelengths"), 500)
})

test_that("non-finite samples are passed through unchanged", {
  tmp <- withr::local_tempfile(fileext = "_SpecCube.dat")
  truth <- array(c(NaN, Inf, -Inf, 0.5), dim = c(2, 2, 1))
  write_cube(truth, tmp)
  expect_identical(as.numeric(tivis_read_cube(tmp)), as.numeric(truth))
})

test_that("profiled reads reject wavelengths that do not match the bands", {
  f <- tivis_example_file()
  expect_error(tivis_read_cube_profiled(f, wavelengths = 1:3),
               "must match source bands")
  expect_error(tivis_read_cube_profiled(f, wavelengths = c(1:7, NA)),
               "must match source bands")
  expect_error(tivis_read_cube_profiled(f, wavelengths = letters[1:8]),
               "must match source bands")
  err <- expect_error(tivis_read_cube_profiled(f, wavelengths = 1:3))
  expect_match(conditionMessage(err), "8 finite numbers")
  expect_match(conditionMessage(err), "length 3")
})

test_that("profiled reads subset declared wavelengths with the bands", {
  f <- tivis_example_file()
  wl <- seq(600, 670, by = 10)
  out <- tivis_read_cube_profiled(f, wavelengths = wl, bands = c(8, 2))
  expect_equal(dim(out), c(12L, 16L, 2L))
  expect_equal(attr(out, "wavelengths"), c(670, 610))
  expect_identical(attr(out, "wavelength_evidence"), "caller_declared")
  expect_equal(out[, , 1], tivis_read_cube(f)[, , 8])

  unknown <- tivis_read_cube_profiled(f, bands = 1:2)
  expect_identical(attr(unknown, "wavelengths"), c(NA_real_, NA_real_))
})
