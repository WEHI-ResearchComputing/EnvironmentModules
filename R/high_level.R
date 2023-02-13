# High level, user-friendly functions

#' Loads one or more environment modules
#' @param ... Any number of modules to load as character vectors, which will
#' all be concatenated together.
#' @return An invisible value whose value may be changed in the future.
#' @export
#' @examples
#' module_load("python")
module_load = function(...){
  modules = c(...)
  code = c("load", modules) |> get_module_code()

  if (length(code) == 0){
    cli::cli_alert_info("Nothing to do. This module was probably already loaded. Use module_list() to verify.")
  }
  else {
    eval(code)
    cli::cli_alert_success("Successfully loaded {modules}")
  }
  invisible(TRUE)
}

#' Unloads one or more environment modules
#' @param ... Any number of modules to unload as character vectors, which will
#' all be concatenated together.
#' @return An invisible value whose value may be changed in the future.
#' @export
#' @examples
#' module_unload("python")
module_unload = function(...){
  modules = c(...)
  code = c("unload", modules) |> get_module_code()

  if (length(code) == 0){
    cli::cli_alert_info("Nothing to do. This module was probably not loaded. Use module_list() to verify.")
  }
  else {
    eval(code)
    cli::cli_alert_success("Successfully unloaded {modules}")
  }
  invisible(TRUE)
}

#' Lists all modules that are currently loaded
#' @inherit get_module_output return
#' @param starts_with An optional character scalar. If provided, only modules
#' whose name starts with this character string will be returned.
#' @param contains An optional character scalar. This parameter is only
#' supported in Environment Modules 4.3+. If provided, it will filter modules
#' to only those containing this substring.
#' @export
#' @examples
#' module_list()
module_list = function(starts_with = NULL, contains = NULL){
  args = c("list", starts_with)
  if (!is.null(contains)){
    check_version("4.3.0", "to use the contains argument")
    args = c(args, "--contains", contains)
  }
  get_module_output(args)
}

#' Lists all modules available to be loaded
#' @inheritParams module_list
#' @inherit get_module_output return
#' @export
#' @examples
#' module_avail()
module_avail = function(starts_with = NULL, contains = NULL){
  args = c("avail", starts_with)
  if (!is.null(contains)){
    check_version("4.3.0", "to use the contains argument")
    args = c(args, "--contains", contains)
  }
  get_module_output(args = args)
}

#' Unloads all modules that are currently loaded
#' @return An invisible value whose value may be changed in the future.
#' @export
#' @examples
#' module_purge()
module_purge = function(){
  get_module_code("purge") |> eval()
  invisible(TRUE)
}

#' Unloads one module, and loads a second module.
#' @param from A character scalar: the module to unload
#' @param to A character scalar: the module to load
#' @return An invisible value whose value may be changed in the future.
#' @export
#' @examples
#' module_swap("python/2", "python/3")
module_swap = function(from, to){
  get_module_code(c("swap", from, to)) |> eval()
  invisible(TRUE)
}
