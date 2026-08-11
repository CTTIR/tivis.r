example_log <- function() {
  system.file("extdata", "example_meta.log", package = "tivis.r")
}

test_that("the German INI dialect parses into sections", {
  m <- tivis_get_metadata(example_log())
  expect_named(m, c("Camera", "SW", "Fremdlichterkennung", "Aufnahme"))
  expect_equal(m$Camera$Exposure, 90)
  expect_equal(m$Aufnahme$Aufnahmemodus, "Reflektanz")
})

test_that("comma decimals become numerics", {
  m <- tivis_get_metadata(example_log())
  v <- m$Fremdlichterkennung$`Intensity Grenzwert`
  expect_type(v, "double")
  expect_equal(v, 7)
})

test_that("booleans become logicals, not strings", {
  m <- tivis_get_metadata(example_log())
  expect_identical(m$Fremdlichterkennung$`Fremdlicht erkannt?`, FALSE)
})

test_that("quotes are stripped and latin1 survives", {
  m <- tivis_get_metadata(example_log())
  expect_false(startsWith(m$SW$Version, "\""))
  expect_equal(m$SW$Version, "1.6.0.1")
  # the Suite writes a latin1 registered-trademark sign
  expect_true(grepl("TIVITA", m$SW$Name, fixed = TRUE))
})

test_that("a missing log yields an empty list rather than an error", {
  expect_identical(tivis_get_metadata(tempfile()), list())
})

test_that("text containing a comma is not mangled into a number", {
  tmp <- tempfile(fileext = ".log")
  on.exit(unlink(tmp), add = TRUE)
  writeLines(c("[S]", 'Note = "one, two"', "Val = 3,5"), tmp)
  m <- tivis_get_metadata(tmp)
  expect_equal(m$S$Note, "one, two")
  expect_equal(m$S$Val, 3.5)
})

test_that("timestamps parse from TIVITA filenames", {
  ts <- tivis_parse_timestamp("2019_11_25_13_29_24_SpecCube.dat")
  expect_s3_class(ts, "POSIXct")
  expect_equal(format(ts, "%Y-%m-%d %H:%M:%S", tz = "UTC"), "2019-11-25 13:29:24")
  expect_true(is.na(tivis_parse_timestamp("not-a-tivita-name.dat")))
})

test_that("reference images are found and labelled", {
  dir <- withr::local_tempdir()
  for (p in c("RGB-Image", "Oxygenation", "THI")) {
    file.create(file.path(dir, paste0("2019_11_25_13_29_24_", p, ".png")))
  }
  file.create(file.path(dir, "2019_11_25_13_29_24_SpecCube.dat"))

  refs <- tivis_reference_images(file.path(dir, "2019_11_25_13_29_24_SpecCube.dat"))
  expect_setequal(names(refs), c("RGB-Image", "Oxygenation", "THI"))
  expect_true(all(file.exists(refs)))
})

test_that("discovery returns an empty frame when nothing matches", {
  dir <- withr::local_tempdir()
  res <- tivis_list_measurements(dir)
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 0L)
})

test_that("discovery finds and describes a recording", {
  dir <- withr::local_tempdir()
  file.copy(tivis_example_file(), file.path(dir, "2020_01_02_03_04_05_SpecCube.dat"))
  res <- tivis_list_measurements(dir)

  expect_equal(nrow(res), 1L)
  expect_equal(res$width, 16L)
  expect_equal(res$height, 12L)
  expect_equal(res$bands, 8L)
  expect_equal(format(res$timestamp, "%Y-%m-%d", tz = "UTC"), "2020-01-02")
})

test_that("tivis_measurement bundles cube, metadata and references", {
  m <- tivis_measurement(tivis_example_file())
  expect_equal(dim(m$cube), c(12L, 16L, 8L))
  expect_equal(m$wavelengths, tivis_get_wavelengths(8L))
  expect_type(m$metadata, "list")
  expect_type(m$references, "character")
})
