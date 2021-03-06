source("incl/start.R")
library("listenv")

message("*** batchtools_multicore() ...")

for (cores in 1:min(2L, availableCores("multicore"))) {
  ## FIXME:
  if (!fullTest && cores > 1) next

  ## CRAN processing times:
  ## On Windows 32-bit, don't run these tests
  if (!fullTest && isWin32) next

  mprintf("Testing with %d cores ...\n", cores)
  options(mc.cores = cores - 1L)

  if (!supportsMulticore()) {
    mprintf("batchtools multicore futures are not supporting on '%s'. Falling back to use synchroneous batchtools local futures\n", .Platform$OS.type) #nolint
  }

  for (globals in c(FALSE, TRUE)) {
    mprintf("*** batchtools_multicore(..., globals = %s) without globals\n",
            globals)

    f <- batchtools_multicore({
      42L
    }, globals = globals)
    stopifnot(
      inherits(f, "BatchtoolsFuture") ||
      ((cores == 1 || !supportsMulticore()) && inherits(f, "SequentialFuture"))
    )

    print(resolved(f))
    y <- value(f)
    print(y)
    stopifnot(y == 42L)
    
    mprintf("*** batchtools_multicore(..., globals = %s) with globals\n",
          globals)
    ## A global variable
    a <- 0
    f <- batchtools_multicore({
      b <- 3
      c <- 2
      a * b * c
    }, globals = globals)

    ## A multicore future is evaluated in a separated
    ## forked process.  Changing the value of a global
    ## variable should not affect the result of the
    ## future.
    a <- 7  ## Make sure globals are frozen
    if (globals || f$config$reg$cluster.functions$name == "Multicore") {
      v <- value(f)
      print(v)
      stopifnot(v == 0)
    } else {
      res <- tryCatch({ value(f) }, error = identity)
      print(res)
      stopifnot(inherits(res, "simpleError"))
    }


    mprintf("*** batchtools_multicore(..., globals = %s) with globals and blocking\n", globals) #nolint
    x <- listenv()
    for (ii in 1:2) {
      mprintf(" - Creating batchtools_multicore future #%d ...\n", ii)
      x[[ii]] <- batchtools_multicore({ ii }, globals = globals)
    }
    mprintf(" - Resolving %d batchtools_multicore futures\n", length(x))
    if (globals || f$config$reg$cluster.functions$name == "Multicore") {
      v <- unlist(value(x))
      stopifnot(all(v == 1:2))
    } else {
      v <- lapply(x, FUN = function(f) tryCatch(value(f), error = identity))
      stopifnot(all(sapply(v, FUN = inherits, "simpleError")))
    }
  } # for (globals ...)

  if (cores > 1) {
    message("*** batchtools_multicore(..., workers = 1L) ...")
  
    a <- 2
    b <- 3
    y_truth <- a * b
  
    f <- batchtools_multicore({ a * b }, workers = 1L)
    rm(list = c("a", "b"))
  
    v <- value(f)
    print(v)
    stopifnot(v == y_truth)
  
    message("*** batchtools_multicore(..., workers = 1L) ... DONE")
  }

  mprintf("Testing with %d cores ... DONE\n", cores)
} ## for (cores ...)


## CRAN processing times:
## On Windows 32-bit, don't run these tests
if (fullTest || !isWin32) {
  mprintf("*** batchtools_multicore() and errors\n")
  f <- batchtools_multicore({
    stop("Whoops!")
    1
  })
  v <- value(f, signal = FALSE)
  print(v)
  stopifnot(inherits(v, "simpleError"))
  
  res <- try(value(f), silent = TRUE)
  print(res)
  stopifnot(inherits(res, "try-error"))
  
  ## Error is repeated
  res <- try(value(f), silent = TRUE)
  print(res)
  stopifnot(inherits(res, "try-error"))
}

message("*** batchtools_multicore() ... DONE")

source("incl/end.R")
