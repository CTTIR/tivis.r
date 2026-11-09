## Submission

This is a new submission.

`tivis.r` reads hyperspectral recordings written by the Diaspective Vision
'TIVITA Suite'. It is pure R: no vendor SDK, no compiled code. The example
cube shipped in `inst/extdata` is a small synthetic file (8 KB), so all
examples, tests and the vignette run offline.

## Test environments

* local: macOS (aarch64), R 4.6.1 — `R CMD check --as-cran --no-manual`
  (no LaTeX installation available locally, hence `--no-manual`; the PDF
  manual still needs to be checked, e.g. on win-builder, before submission)
* GitHub Actions (r-lib/actions v2, `--as-cran`):
  * macOS-latest (release)
  * windows-latest (release)
  * ubuntu-latest (devel, release, oldrel-1)

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'R. Heller <raban.heller@uni-ulm.de>'
  New submission

  This is the first submission of this package.

## Downstream dependencies

There are currently no downstream dependencies on CRAN.
