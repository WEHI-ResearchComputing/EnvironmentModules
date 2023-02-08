# High level, user-friendly functions

#' Loads one or more environment modules
#' @param modules A character vector of environment modules to load
#' @param link_libs A logical scalar. If TRUE, link R to all the shared
#'  libraries contained within that module. This is not the default behaviour.
#' @inheritParams get_module_code
#' @inheritDotParams link_module_libs
#' @return A list of `DLLInfo` objects, containing the libraries (if any)
#'  that were linked. See [base::getLoadedDLLs] for an explanation of this
#'  class.
#' @export
#' @examples
#' module_load("python")
module_load = function(modules, link_libs = FALSE, env = character(), ...){
  initial_ld = Sys.getenv("LD_LIBRARY_PATH")

  code = c("load", modules) |> get_module_code(env = env)

  if (length(code) == 0){
    cli::cli_alert_info("Nothing to do. This module was probably already loaded. Use module_list() to verify.")
  }
  else {
    eval(code)
    cli::cli_alert_success("Successfully loaded {modules}")
  }

  if (link_libs){
    diff_libs(Sys.getenv("LD_LIBRARY_PATH"), initial_ld) |>
      link_module_libs(unlink = FALSE, ...) |>
      invisible()
  } else {
    list() |> invisible()
  }
}

#' Unloads one or more environment modules
#' @param modules A character vector of environment modules to unload
#' @param unlink_libs A logical scalar. If TRUE, unlink R from all the shared
#'  libraries contained within that module. This is not the default behaviour.
#' @inheritParams get_module_code
#' @inheritDotParams link_module_libs
#' @return A list of `DLLInfo` objects, containing the libraries (if any)
#'  that were linked. See [base::getLoadedDLLs] for an explanation of this
#'  class.
#' @export
#' @examples
#' module_unload("python")
module_unload = function(modules, unlink_libs = FALSE, env = character(), ...){
  initial_ld = Sys.getenv("LD_LIBRARY_PATH")

  code = c("unload", modules) |> get_module_code(env = env)

  if (length(code) == 0){
    cli::cli_alert_info("Nothing to do. This module was probably not loaded. Use module_list() to verify.")
  }
  else {
    eval(code)
    cli::cli_alert_success("Successfully unloaded {modules}")
  }

  if (unlink_libs){
    diff_libs(initial_ld, Sys.getenv("LD_LIBRARY_PATH")) |>
      link_module_libs(unlink = TRUE, ...) |>
      invisible()
  } else {
    list() |> invisible()
  }
}

#' Lists all modules that are currently loaded
#' @return The same format as [get_module_output()]
#' @param starts_with An optional character scalar. If provided, only modules
#' whose name starts with this character string will be returned.
#' @param contains An optional character scalar. This parameter is only
#' supported in Environment Modules 4.3+. If provided, it will filter modules
#' to only those containing this substring.
#' @inheritParams get_module_output
#' @export
#' @examples
#' module_list()
module_list = function(starts_with = NULL, contains = NULL, env = character()){
  args = c("list", starts_with)
  if (!is.null(contains)){
    args = c(args, "--contains", contains)
  }
  get_module_output(args, env = env)
}

#' Unloads all modules that are currently loaded
#' @return Invisible
#' @inheritParams get_module_output
#' @export
#' @examples
#' module_purge()
module_purge = function(env = character(0)){
  get_module_code("purge", env = env) |> eval()
  invisible(TRUE)
}

#' Unloads one module, and loads a second module.
#' @details Note that this doesn't have all the functionality of [module_load()]
#'  and [module_unload()], so you may want to use those for more control.
#' @param from A character scalar: the module to unload
#' @param to A character scalar: the module to load
#' @inheritParams get_module_code
#' @return Invisible
#' @export
#' @examples
#' module_swap("python/2", "python/3")
module_swap = function(from, to, env = character()){
  get_module_code(c("swap", from, to), env = env) |> eval()
  invisible(TRUE)
}

#' Lists all modules available to be loaded
#' @return The same format as [get_module_output()]
#' @inheritParams module_list
#' @export
#' @examples
#' module_avail()
module_avail = function(starts_with = NULL, contains = NULL, env = character()){
  args = c("avail", starts_with)
  if (!is.null(contains)){
    args = c(args, "--contains", contains)
  }
  get_module_output(args = args, env = env)
}

#' Links R to the shared libraries in a number of directories
#'
#' @param ld_library_paths A character vector indicating directories to search
#'  in.
#' @param unlink If TRUE, then unlink the libraries rather than linking them
#' @param verbose If TRUE, print out each library that is loaded or unloaded
#' @return A list of `DLLInfo` objects describing the newly linked shared
#'  libraries
#' @export
#' @examples
#' lib_dir = file.path(R.home(), "lib")
#' link_module_libs(lib_dir)
link_module_libs = function(ld_library_paths, unlink = FALSE, verbose = FALSE){
  ld_library_paths |>
    list.files(pattern = ".*\\.so", full.names = TRUE) |>
    normalizePath() |>
    unique() |>
    lapply(\(lib){
      if (unlink){
        result = dyn.unload(lib) |> try(silent=TRUE)
        if (verbose && inherits(result, "try-error")){
          cli::cli_alert_danger("Failed to unload {lib}: {result}")
        }
        else {
          cli::cli_alert_success("Successfully unloaded {lib}")
        }
      }
      else {
        result = dyn.load(lib, now=FALSE, local=FALSE) |> try(silent=TRUE)
        if (verbose && inherits(result, "try-error")){
          cli::cli_alert_danger("Failed to load {lib}: {result}")
        }
        else {
          cli::cli_alert_success("Successfully loaded {lib}")
        }
      }
    })
}
