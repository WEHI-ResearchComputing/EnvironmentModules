

get_quarantine_old = function(){
  mlre <- ''
  if (!is.na(Sys.getenv('MODULES_RUN_QUARANTINE', unset=NA))) {
    for (mlv in strsplit(Sys.getenv('MODULES_RUN_QUARANTINE'), ' ')[[1]]) {
      if (grepl('^[A-Za-z_][A-Za-z0-9_]*$', mlv)) {
        if (!is.na(Sys.getenv(mlv, unset=NA))) {
          mlre <- paste0(mlre, "__MODULES_QUAR_", mlv, "='", Sys.getenv(mlv), "' ")
        }
        mlrv <- paste0('MODULES_RUNENV_', mlv)
        mlre <- paste0(mlre, mlv, "='", Sys.getenv(mlrv), "' ")
      }
    }
    if (mlre != '') {
      mlre <- paste0('env ', mlre, '__MODULES_QUARANTINE_SET=1 ')
    }
  }
  mlre
}

get_quarantine = function(){
  # setup quarantine if defined
  quarantine_var = Sys.getenv('MODULES_RUN_QUARANTINE', unset=NA)
  if (is.na(quarantine_var)){
    stop("Quarantine is not yet implemented")
    quarantine_var |>
      strsplit(' ') |>
      head(1) |>
      purrr::keep(~ grepl('^[A-Za-z_][A-Za-z0-9_]*$', .)) |>
      lapply(\(mlv){
        mlv_env = Sys.getenv(mlv, unset=NA)
        mlrv = glue::glue("MODULES_RUNENV_{mlv}")

        prefix = mlv_env |>
          is.na() |>
          {`if`}(
            "",
            glue::glue("__MODULES_QUAR_{module}={mlv_env} ")
          )

        glue::glue("{prefix}{mlv}={Sys.getenv(mlrv)}")
      })
  }
  else {
    NULL
  }
}

get_modulescmd_binary = function(){
  Sys.getenv("MODULES_CMD")
}

#' Returns the R code that would execute a given module command
#' @param args A character vector defining the module command
#' @return An expression object containing the R code produced by this command
#' @export
#' @examples
#' get_module_code("purge") |> eval()
get_module_code = function(args){
  c(
    "r",
    args
  ) |>
    system2(
      get_modulescmd_binary(),
      args=_,
      stdout=TRUE,
      stderr=FALSE,
    ) |>
    parse(text = _)
}

#' Evaluates a module command, and returns the text output.
#' @param args A character vector containing the module subcommand to run,
#'  followed by any arguments for that command
#' @return A character vector with class "cli_ansi_string". If you have the
#'  cli package installed an loaded, it will enable enhanced
#'  printing of this result. If you don't want to install cli, you should print
#'  this result out using [base::cat] and *not* [base::print] to ensure the
#'  ANSI control characters are correctly displayed.
#' @export
#' @examples
#' get_module_command("list") |> cat()
get_module_output = function(args){
  c(
    "r",
    args
  ) |>
    system2(
      get_modulescmd_binary(),
      args=_,
      stdout=TRUE,
      stderr=TRUE,
    ) |>
    `class<-`(c("cli_ansi_string", "ansi_string", "character"))
}

#' Loads one or more environment modules
#' @param modules A character vector of environment modules to load
#' @param link_libs A logical scalar. If TRUE, link R to all the shared
#'  libraries contained within that module. This is not the default behaviour.
#' @return A list of `DLLInfo` objects, containing the libraries (if any)
#'  that were linked. See [base::getLoadedDLLs] for an explanation of this
#'  class.
#' @export
#' @examples
#' module_load("python")
module_load = function(modules, link_libs = FALSE){
  initial_ld = Sys.getenv("LD_LIBRARY_PATH")

  c("load", modules) |>
    get_module_command() |>
    eval()

  if (link_libs){
    initial_ld = strsplit(initial_ld, ":")
    final_ld = Sys.getenv("LD_LIBRARY_PATH") |> strsplit(":")
    setdiff(initial_ld, final_ld) |>
      link_module_libs()
  } else {
    list()
  }
}

#' Lists all modules that are currently loaded
#' @return The same format as [get_module_output()]
#' @export
#' @examples
#' module_list() |> cat()
module_list = function(){
  get_module_output("list")
}

#' Unloads all modules that are currently loaded
#' @return Invisible
#' @export
#' @examples
#' module_purge()
module_purge = function(){
  get_module_code("purge") |> eval()
  invisible(TRUE)
}

#' Unloads one module, and loads a second module
#' @return Invisible
#' @export
#' @examples
#' module_swap("python/2", "python/3")
module_swap = function(from, to){
  get_module_code(c("purge", from, to)) |> eval()
  invisible(TRUE)
}

#' Lists all modules available to be loaded
#' @return The same format as [get_module_output()]
#' @export
#' @examples
#' module_avail() |> cat()
module_avail = function(){
  get_module_output("avail")
}

#' Links R to the shared libraries in a number of directories
#'
#' @param ld_library_paths A character vector indicating directories to search
#'  in.
#' @inheritDotParams dyn.load
#' @return A list of `DLLInfo` objects describing the newly linked shared
#'  libraries
#' @export
#' @examples
#' lib_dir = file.path(R.home(), "lib")
#' link_module_libs(lib_dir)
link_module_libs = function(ld_library_paths, ...){
  ld_library_paths |>

    list.files(pattern = ".*\\.so", full.names = TRUE) |>
    normalizePath() |>
    unique() |>
    lapply(dyn.load, ...)
}
