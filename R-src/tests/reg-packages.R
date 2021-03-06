## PR 1271  detach("package:base") crashes R.
tools::assertError(detach("package:base"))


## invalid 'lib.loc'
stopifnot(length(installed.packages("mgcv")) == 0)
## gave a low-level error message


## package.skeleton() with metadata-only code
## work in current (= ./tests/ directory):
tmp <- tempfile()
writeLines(c('setClass("foo", contains="numeric")',
             'setMethod("show", "foo",',
             '          function(object) cat("I am a \\"foo\\"\\n"))'),
           tmp)
if(file.exists("myTst")) unlink("myTst", recursive=TRUE)
package.skeleton("myTst", code_files = tmp)# with a file name warning
file.copy(tmp, (tm2 <- paste(tmp,".R", sep="")))
unlink("myTst", recursive=TRUE)
op <- options(warn=2) # *NO* "invalid file name" warning {failed in 2.7.[01]}:
package.skeleton("myTst", code_files = tm2)
options(op)
##_2_ only a class, no generics/methods:
writeLines(c('setClass("DocLink",',
             'representation(name="character",',
             '               desc="character"))'), tmp)
if(file.exists("myTst2")) unlink("myTst2", recursive=TRUE)
package.skeleton("myTst2", code_files = tmp)
##- end_2_ # failed in R 2.11.0
stopifnot(1 == grep("setClass",
	  readLines(list.files("myTst/R", full.names=TRUE))),
	  c("foo-class.Rd","show-methods.Rd") %in% list.files("myTst/man"))
## failed for several reasons in R < 2.7.0
##
## Part 2: -- build, install, load and "inspect" the package:
build.pkg <- function(dir) {
    stopifnot(dir.exists(dir))
    patt <- paste(basename(dir), ".*tar\\.gz$", sep="_")
    unlink(dir('.', pattern = patt))
    Rcmd <- paste(file.path(R.home("bin"), "R"), "CMD")
    r <- tail(system(paste(Rcmd, "build --keep-empty-dirs", shQuote(dir)),
                     intern = TRUE), 3)
    ## return name of tar file built
    dir('.', pattern = patt)
}
build.pkg("myTst")
## clean up any previous attempt (which might have left a 00LOCK)
unlink("myLib", recursive = TRUE)
dir.create("myLib")
install.packages("myTst", lib = "myLib", repos=NULL, type = "source") # with warnings
print(installed.packages(lib.loc= "myLib", priority= "NA"))## (PR#13332)
stopifnot(require("myTst",lib = "myLib"))
sm <- findMethods(show, where= as.environment("package:myTst"))
stopifnot(names(sm@names) == "foo")
unlink("myTst_*")

## getPackageName()  for "package:foo":
require('methods')
library(tools)
oo <- options(warn=2)
detach("package:tools", unload=TRUE)
options(oo)
## gave warning (-> Error) about creating package name

## --- keep this at end --- so we do not need a large if(.) { .. }
## More building & installing packages
## NB: tests were added here for 2.11.0.
## NB^2: do not do this in the R sources!
## and this testdir is not installed.
pkgSrcPath <- file.path(Sys.getenv("SRCDIR"), "Pkgs")
if(!file_test("-d", pkgSrcPath) && !interactive()) {
    unlink("myTst", recursive=TRUE)
    print(proc.time())
    q("no")
}

## else w/o clause:
## could use file.copy(recursive = TRUE)
system(paste('cp -R', shQuote(pkgSrcPath), shQuote(tempdir())))
pkgPath <- file.path(tempdir(), "Pkgs")
## pkgB tests an empty R directory
dir.create(file.path(pkgPath, "pkgB", "R"), recursive = TRUE,
	   showWarnings = FALSE)
p.lis <- if("Matrix" %in% row.names(installed.packages(.Library)))
	     c("pkgA", "pkgB", "exNSS4") else "exNSS4"
for(p. in p.lis) {
    cat("building package", p., "...\n")
    r <- build.pkg(file.path(pkgPath, p.))
    cat("installing package", p., "using file", r, "...\n")
    ## we could install the tar file ... (see build.pkg()'s definition)
    install.packages(r, lib = "myLib", repos=NULL, type = "source")
    stopifnot(require(p.,lib = "myLib", character.only=TRUE))
    detach(pos = match(p., sub("^package:","", search())))
}
(res <- installed.packages(lib.loc = "myLib", priority = "NA"))
stopifnot(identical(res[,"Package"], setNames(,sort(c(p.lis, "myTst")))),
	  res[,"LibPath"] == "myLib")
### Specific Tests on our "special" packages: ------------------------------

## Find objects which are NULL via "::" -- not to be expected often
## we have one in our pkgA, but only if Matrix is present
if(dir.exists(file.path("myLib", "pkgA"))) {
  require(pkgA, lib="myLib")
  data(package = "pkgA") # -> nilData
  stopifnot(is.null( pkgA::  nil),
	    is.null( pkgA::: nil),
	    is.null( pkgA::  nilData)) # <-
  ## R-devel (pre 3.2.0) wrongly errored for NULL lazy data
  ## ::: does not apply to data sets:
  tools::assertError(is.null(pkgA:::nilData))
}

## tests here should *NOT* assume recommended packages,
## let alone where they are installed
if(dir.exists(file.path("myLib", "exNSS4")) &&
   dir.exists(file.path(.Library, "Matrix"))) {
    for(ns in c("pkgB", "pkgA", "Matrix", "exNSS4")) unloadNamespace(ns)
    ## Both exNSS4 and Matrix define "atomicVector" *the same*,
    ## but  'exNSS4'  has it extended - and hence *both* are registered in cache -> "conflicts"
    requireNamespace("exNSS4", lib= "myLib")
    requireNamespace("Matrix", lib= .Library)
    tools::assertCondition( ## condition, because this *still* uses message():
        acl <- getClass("atomicVector")
    ) ## gave an Error: “atomicVector” is not a defined class
    ##   ... because it was found non-uniquely
    stopifnot(is(acl, "classRepresentation"), isVirtualClass(acl))
}

## clean up
unlink("myLib", recursive = TRUE)
unlink(file.path(pkgPath), recursive = TRUE)
unlink("myTst", recursive = TRUE)

proc.time()
