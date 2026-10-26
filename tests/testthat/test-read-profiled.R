test_that("profiled arrays retain layout and unknown wavelength evidence", {
  path <- tempfile(fileext = "_SpecCube.dat")
  on.exit(unlink(path), add = TRUE)
  con <- file(path, "wb")
  writeBin(as.integer(c(5, 2, 3)), con, size = 4, endian = "big")
  expected <- array(NA_real_, c(2, 5, 3))
  for (x in 1:5) {
    for (y in 1:2) {
      for (b in 1:3) {
        value <- y * 1000 + x * 100 + b
        writeBin(value, con, size = 4, endian = "big")
        expected[y, x, b] <- value
      }
    }
  }
  close(con)
  result <- tivis_read_cube_profiled(path)
  expect_identical(as.numeric(result), as.numeric(expected))
  expect_true(all(is.na(attr(result, "wavelengths"))))
  expect_identical(attr(result, "wavelength_evidence"), "unavailable")
  expect_identical(attr(tivis_read_cube_profiled(path, c(
    500, 600,
    700
  ), 2), "wavelengths"), 600)
})
