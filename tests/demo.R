source("incl/start.R")

plan(batchtools_local)

## CRAN processing times:
## On Windows 32-bit, don't run these tests via batchtools
if (!fullTest && isWin32) plan(sequential)

options(future.demo.mandelbrot.nrow = 2L)
options(future.demo.mandelbrot.resolution = 50L)
options(future.demo.mandelbrot.delay = FALSE)

message("*** Demos ...")

message("*** Mandelbrot demo of the 'future' package ...")

demo("mandelbrot", package = "future", ask = FALSE)

message("*** Demos ... DONE")

source("incl/end.R")
