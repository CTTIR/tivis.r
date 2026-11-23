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
  # the Suite writes a latin1 registered-trademark sign (byte 0xAE); it must
  # arrive as that character, in UTF-8, not merely leave "TIVITA" intact
  expect_identical(m$SW$Name, "TIVITA\u00ae Suite")
  expect_identical(Encoding(m$SW$Name), "UTF-8")
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
  ts <- tivis_parse_timestamp("2000_01_01_12_00_00_SpecCube.dat")
  expect_s3_class(ts, "POSIXct")
  expect_equal(format(ts, "%Y-%m-%d %H:%M:%S", tz = "UTC"),
               "2000-01-01 12:00:00")
  expect_true(is.na(tivis_parse_timestamp("not-a-tivita-name.dat")))
})

test_that("reference images are found and labelled", {
  dir <- withr::local_tempdir()
  for (p in c("RGB-Image", "Oxygenation", "THI")) {
    file.create(file.path(dir, paste0("2000_01_01_12_00_00_", p, ".png")))
  }
  file.create(file.path(dir, "2000_01_01_12_00_00_SpecCube.dat"))

  refs <- tivis_reference_images(
    file.path(dir, "2000_01_01_12_00_00_SpecCube.dat")
  )
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
  file.copy(tivis_example_file(),
            file.path(dir, "2020_01_02_03_04_05_SpecCube.dat"))
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
  # the bundled cube has a sibling log, and it must be the one that is read
  expect_equal(m$metadata$Camera$Exposure, 90)
  expect_identical(m$path, tivis_example_file())
  # downstream adapters rely on a plain, unclassed list
  expect_identical(class(m), "list")
  expect_named(m, c("cube", "wavelengths", "metadata", "references",
                    "timestamp", "path"))
})

write_log <- function(lines, path, encoding = "UTF-8") {
  con <- file(path, "wb")
  on.exit(close(con), add = TRUE)
  writeLines(iconv(enc2utf8(lines), "UTF-8", encoding), con, useBytes = TRUE)
  invisible(path)
}

test_that("quoted values stay strings", {
  tmp <- withr::local_tempfile(fileext = ".log")
  write_log(c(
    "[S]", 'Id = "0012"', 'Version = "2.0"', 'Flag = "TRUE"',
    'Decimal = "7,50"', "Bare = 0012", 'Empty = ""', "Nothing ="
  ), tmp)
  m <- tivis_get_metadata(tmp)$S
  # coercing these would lose the leading zeros and the trailing ".0"
  expect_identical(m$Id, "0012")
  expect_identical(m$Version, "2.0")
  expect_identical(m$Flag, "TRUE")
  expect_identical(m$Decimal, "7,50")
  expect_identical(m$Bare, 12)
  expect_identical(m$Empty, "")
  expect_identical(m$Nothing, "")
})

test_that("bare numbers and booleans are coerced", {
  tmp <- withr::local_tempfile(fileext = ".log")
  write_log(c(
    "[S]", "A = -3,25", "B = +4", "C = .5", "D = 1.5", "E = true",
    "F = False", "G = 1,2,3", "H = 1e5", "I = 12 mm"
  ), tmp)
  m <- tivis_get_metadata(tmp)$S
  expect_identical(m$A, -3.25)
  expect_identical(m$B, 4)
  expect_identical(m$C, 0.5)
  expect_identical(m$D, 1.5)
  expect_identical(m$E, TRUE)
  expect_identical(m$F, FALSE)
  # not unambiguously numeric: left as text
  expect_identical(m$G, "1,2,3")
  expect_identical(m$H, "1e5")
  expect_identical(m$I, "12 mm")
})

test_that("a UTF-8 log is not decoded a second time", {
  lines <- c("[Ger\u00e4t]", 'Name = "TIVITA\u00ae Suite"',
             "Gr\u00f6\u00dfe = 3,5")
  utf8 <- withr::local_tempfile(fileext = ".log")
  latin1 <- withr::local_tempfile(fileext = ".log")
  write_log(lines, utf8, "UTF-8")
  write_log(lines, latin1, "latin1")
  expect_false(identical(readBin(utf8, "raw", 200),
                         readBin(latin1, "raw", 200)))

  from_utf8 <- tivis_get_metadata(utf8)
  from_latin1 <- tivis_get_metadata(latin1)
  expect_identical(from_utf8, from_latin1)
  expect_named(from_utf8, "Ger\u00e4t")
  expect_identical(from_utf8[[1]]$Name, "TIVITA\u00ae Suite")
  expect_identical(from_utf8[[1]][["Gr\u00f6\u00dfe"]], 3.5)
})

test_that("a byte-order mark does not hide the first section", {
  tmp <- withr::local_tempfile(fileext = ".log")
  con <- file(tmp, "wb")
  writeBin(as.raw(c(0xef, 0xbb, 0xbf)), con)
  writeLines(c("[Camera]", "Exposure = 90"), con)
  close(con)
  expect_identical(tivis_get_metadata(tmp), list(Camera = list(Exposure = 90)))
})

test_that("the INI structure is parsed leniently", {
  tmp <- withr::local_tempfile(fileext = ".log")
  write_log(c(
    "Orphan = 1", "; a comment", "# another = comment", "",
    "[ A ]", "Key = first", "no separator here", "= no key",
    "Key = last", "Url = a=b", "[]", "Late = 2", "[A]", "More = 3",
    "[Empty]"
  ), tmp)
  m <- tivis_get_metadata(tmp)
  expect_named(m, c("general", "A", "Empty"))
  # entries before any header, and under an empty header, go to `general`
  expect_identical(m$general, list(Orphan = 1, Late = 2))
  # a repeated key keeps the last value; a repeated section is merged; only
  # the first "=" separates key and value
  expect_identical(m$A, list(Key = "last", Url = "a=b", More = 3))
  expect_identical(m$Empty, list())
})

test_that("Windows line endings are handled", {
  tmp <- withr::local_tempfile(fileext = ".log")
  writeBin(charToRaw("[S]\r\nA = 1\r\nB = \"x\"\r\n"), tmp)
  expect_identical(tivis_get_metadata(tmp), list(S = list(A = 1, B = "x")))
})

test_that("an empty log and a directory both yield an empty list", {
  tmp <- withr::local_tempfile(fileext = ".log")
  file.create(tmp)
  expect_identical(tivis_get_metadata(tmp), list())
  expect_identical(tivis_get_metadata(withr::local_tempdir()), list())
})

test_that("recordings sharing a directory keep their own reference images", {
  dir <- withr::local_tempdir()
  first <- "2000_01_01_12_00_00_"
  second <- "2000_01_01_12_05_00_"
  for (p in c("RGB-Image", "Oxygenation")) {
    file.create(file.path(dir, paste0(first, p, ".png")))
  }
  file.create(file.path(dir, paste0(second, "THI.PNG")))
  file.create(file.path(dir, "notes.txt"))
  for (stamp in c(first, second)) {
    file.copy(tivis_example_file(),
              file.path(dir, paste0(stamp, "SpecCube.dat")))
  }

  one <- tivis_reference_images(file.path(dir, paste0(first, "SpecCube.dat")))
  two <- tivis_reference_images(file.path(dir, paste0(second, "SpecCube.dat")))
  expect_named(one, c("Oxygenation", "RGB-Image"))
  # the extension is matched case-insensitively
  expect_named(two, "THI")
  # the directory itself still lists everything
  expect_setequal(names(tivis_reference_images(dir)),
                  c("Oxygenation", "RGB-Image", "THI"))

  res <- tivis_list_measurements(dir)
  expect_equal(res$n_reference_images, c(2L, 1L))
})

test_that("a cube without a timestamp sees every image beside it", {
  dir <- withr::local_tempdir()
  file.create(file.path(dir, "Oxygenation.png"))
  file.create(file.path(dir, "2000_01_01_12_00_00_THI.png"))
  refs <- tivis_reference_images(file.path(dir, "example_SpecCube.dat"))
  expect_setequal(names(refs), c("Oxygenation", "THI"))
})

test_that("reference images handle empty and missing directories", {
  dir <- withr::local_tempdir()
  expect_identical(tivis_reference_images(dir), character(0))
  expect_identical(
    tivis_reference_images(file.path(dir, "2000_01_01_12_00_00_SpecCube.dat")),
    character(0)
  )
  expect_error(
    tivis_reference_images(file.path(dir, "missing", "x_SpecCube.dat")),
    "Directory not found"
  )
})

