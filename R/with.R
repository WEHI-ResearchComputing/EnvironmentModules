# withr-style functions for running R code with modules temporarily loaded

#' Bake environment modules into an R package
#' @description Executes a package installation command so that the installed package
#' will be aware of the modules you currently have loaded.
#' This means you can load the package without needing to load that module
#' later, and also that you can load that package now, without restarting your
#' R session.
#' @details This functionality is performed by setting a temporary value of
#' the LDFLAGS environment variable in your Makevars file. It will not work
#' if the R package is not set up to correctly use LDFLAGS, but all
#' correctly configured R packages will automatically do so.
#' Also, it is recommended that you have only the minimal number of modules
#' needed to install this package loaded when you run this.
#' @param expr Any R code you want to run that installs packages. Most of the
#' time this will just be a call to [install.packages]()
#' @return The result of evaluating `expr`
#' @keywords with
#' @export
#' @examples
#' options(repos=c(CRAN="https://cloud.r-project.org/"))
#' module_load("hdf5")
#' install.packages("hdf5r") |> with_module_install()
with_module_install = function(expr){
  withr::with_makevars(
    c(LDFLAGS=paste0("-Wl,-rpath,", Sys.getenv("LD_LIBRARY_PATH"))),
    expr,
    assignment="+="
  )
}

#' Run some R code using an additional set of modules
#' @description Runs some R code with additional modules loaded, in addition to
#'   the currently loaded modules, without affecting your current modules.
#' @param new A character vector of modules to load when executing `code`
#' @param code Any R code to execute
#' @return The result of evaluating `code`
#' @keywords with
#' @export
#' @examples
#' system2("python3", "--version") |> with_extra_modules("python", code=_)
with_extra_modules = withr::with_(set = function(modules){
  module_load(modules)
  modules
}, reset = function(modules){
  module_unload(modules)
})

#' Run some R code using a minimal set of modules
#' @description Runs some R code with no modules loaded except for those that
#'   you provide, without affecting your current modules.
#' @param new A character vector of modules to load when executing `code`
#' @param code Any R code to execute
#' @return The result of evaluating `code`
#' @keywords with
#' @export
#' @examples
#' system2("python3", "--version") |> with_only_modules("python", code=_)
with_only_modules = withr::with_(function(modules){
  current_modules = module_list()
  module_purge()
  if (length(modules) > 0) {
    # Only load modules if we have a non empty vector
    module_load(modules)
  }
  current_modules
})
