# High level, user-friendly functions

# Used to silence R CMD check
mlstatus <- NULL

#' Loads one or more environment modules
#' @param ... Any number of modules to load as character vectors, which will
#' all be concatenated together.
#' @return An invisible value whose value may be changed in the future.
#' @keywords high_level
#' @export
#' @examples
#' module_load("python")
module_load = structure(
  function(...){
    modules = c(...)
    code = c("load", modules) |> get_module_code()

    if (length(code) == 0){
      cli::cli_alert_info("Nothing to do. This module was probably already loaded. Use module_list() to verify.")
    }
    else {
      eval(code)
      if (mlstatus){
        cli::cli_alert_success("Successfully loaded {modules}")
      }
      else {
        cli::cli_abort("Failed to load {modules}")
      }
    }
    invisible(NULL)
  },
  class = c("module_load", "dollar_function", "function")
)

#' Unloads one or more environment modules
#' @param ... Any number of modules to unload as character vectors, which will
#' all be concatenated together.
#' @return An invisible value whose value may be changed in the future.
#' @keywords high_level
#' @export
#' @examples
#' module_unload("python")
module_unload = structure(
  function(...){
    modules = c(...)
    code = c("unload", modules) |> get_module_code()

    if (length(code) == 0){
      cli::cli_alert_info("Nothing to do. This module was probably not loaded. Use module_list() to verify.")
    }
    else {
      eval(code)
      if (mlstatus){
        cli::cli_alert_success("Successfully unloaded {modules}")
      }
      else {
        cli::cli_abort("Failed to unload {modules}")
      }
    }
    invisible(TRUE)
  },
  class = c("module_unload", "dollar_function", "function")
)

#' Lists all modules that are currently loaded
#' @return A character vector whose entries correspond to modules that are
#'  currently loaded
#' @param filter If provided, a character scalar will be used to filter the
#'  results. Only modules containing `filter` as a substring will be returned.
#' @param detailed An optional boolean scalar. If true, returns a list of
#'  metadata about each module.
#' @keywords high_level
#' @export
#' @examples
#' module_list()
module_list = function(filter = "", detailed = FALSE){
  modules = Sys.getenv("LOADEDMODULES") |> strsplit(":") |> unlist()
  modules[grepl(filter, modules, fixed=TRUE)]
}

#' Lists all modules available to be loaded
#' @inheritParams module_list
#'
#' @return A character vector whose entries correspond to available to be
#'  loaded
#' @keywords high_level
#' @export
#' @examples
#' module_avail()
module_avail = function(filter = "", detailed = FALSE){
  if (detailed){
    check_json()
    modules = get_module_output(c("avail", "--json")) |>
      jsonlite::fromJSON(simplifyVector=FALSE) |>
      do.call(c, args=_)
    modules[grepl(filter, x=names(modules), fixed=TRUE)] |>
      unname() |>
      lapply(\(row){
        lapply(row, \(cell){
          if (is.list(cell)){
            list(cell)
          }
          else {
            cell
          }
        }) |> list2DF()
      }) |>
      do.call(rbind, args=_)
  }
  else {
    modules = Sys.getenv("MODULEPATH") |>
      strsplit(":") |>
      unlist() |>
      list.files(recursive=TRUE, include.dirs=FALSE)
    modules[grepl(filter, modules, fixed=TRUE)]
  }
}

#' Unloads all modules that are currently loaded
#' @return An invisible value whose value may be changed in the future.
#' @keywords high_level
#' @export
#' @examples
#' module_purge()
module_purge = function(){
  code = get_module_code("purge")

  if (length(code) == 0){
    cli::cli_alert_info("Nothing to do. Most likely no modules were loaded.")
  }
  else {
    eval(code)
    if (mlstatus){
      cli::cli_alert_success("Successfully purged modules")
    }
    else {
      cli::cli_abort("Failed to purge modules")
    }
  }
  invisible(NULL)
}

#' Unloads one module, and loads a second module.
#' @param from A character scalar: the module to unload
#' @param to A character scalar: the module to load
#' @return An invisible value whose value may be changed in the future.
#' @keywords high_level
#' @export
#' @examples
#' module_swap("python/2", "python/3")
module_swap = function(from, to){
  get_module_code(c("swap", from, to)) |> eval()
  invisible(TRUE)
}
