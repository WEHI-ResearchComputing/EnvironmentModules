# Implementation of autocompletions

#' Get autocompletions for [module_load()]
#' @param x The `module_load` function
#' @param pattern Ignored
#' @return A character vector of available modules
#' @export
.DollarNames.module_load = function(x, pattern){
  get_available_modules()
}

#' Calls a function using the name used after the dollar sign
#' @param x The function to call
#' @param name The name to pass in to the function
#' @return The return value of `x`
#' @export
`$.dollar_function` = function(x, name){
  x(name)
}

#' Get autocompletions for [module_unload()]
#' @param x The `module_unload` function
#' @param pattern Ignored
#' @return A character vector of currently-loaded modules
#' @export
.DollarNames.module_unload = function(x, pattern){
  get_loaded_modules()
}
