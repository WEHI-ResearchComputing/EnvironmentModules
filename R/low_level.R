# Low level, user-unfriendly functions

MIN_SUPPORTED_VERSION = numeric_version("4.0.0")

diff_libs = function(previous, current){
  setdiff(
    strsplit(previous, ":") |> unlist(),
    strsplit(current, ":") |> unlist()
  )
}

#' Returns the current Environment Modules version which can be used for
#' feature testing
#' @return The current Environment Modules version as a [base::numeric_version]
#' object, or NULL if no version can be detected.
#' @keywords low_level
#' @export
#' @examples
#' version = check_version()
#' version < numeric_version("5.0.0")
get_version = function(){
  output = system2(
    get_modulescmd_binary(),
    c("sh", "--version"),
    stderr=TRUE,
    stdout=TRUE
  )[[1]] |>
    suppressWarnings()
  match = regexec("\\d+\\.\\d+\\.\\d+", output)[[1]]
  if (match == -1){
    NULL
  }
  else {
    end = attr(match, "match.length")
    substr(output, match, match + end - 1) |>
      numeric_version()
  }
}

#' Asserts that the current EnvironmentModules version is above a specified
#' version. Raises an error if it is not.
#' @param against The version to check against. By default this is the minimum
#' version supported by this package.
#' @param action A character scalar describing the action that is being
#' attempted, in the infinitive conjugation (e.g. "to run X" or "for running Y")
#' @return An invisible value whose value may be changed in the future.
#' @keywords low_level
#' @export
#' @examples
#' check_version()
check_version = function(against=MIN_SUPPORTED_VERSION, action="for the function you just ran"){
  minimum = numeric_version(against)
  version = get_version()
  if (version < minimum || is.null(version)){
    cli::cli_abort("Your Environment Modules version is {version}, which is lower than {minimum}, which is required {action}.")
  }
  invisible()
}

#' Gets the file path to the `modulescmd` executable
#' @keywords low_level
#' @export
#' @return A character scalar containing the full file path to the `modulescmd`
#'  executable
get_modulescmd_binary = function(){
  env_src = Sys.getenv("MODULES_CMD")
  which_src = Sys.which("modulecmd")

  if (file.exists(env_src)){
    env_src
  }
  else if (file.exists(which_src)) {
    which_src |> unname()
  }
  else {
    cli::cli_abort(
    "Could not detect an Environment Modules installation.
    Are you sure it is installed on this machine?
    If yes, try setting the MODULES_CMD environment variable to a valid path."
    )
  }
}

#' Runs `modulecmd` with some arguments. The shell is harcoded as "r" because
#' (surprise!) that's the language you are using right now.
#' @keywords low_level
#' @details This is a low-level unexported function because users are
#'  encouraged to use the higher level functions such as [module_load()]
#' @param args A character vector defining the module command. You do not need
#'  to include the word "module". For example `module load zeromq` in bash
#'  could be converted to `run_modulecmd(c("load", "zeromq"))`
#' @param ... Arguments to forward to [base::system2()]
#' @return A character scalar containing the command's output
run_modulecmd = function(args, ...){
  check_version()
  c("r", args) |> system2(command = get_modulescmd_binary(), args=_, ...)
}

#' Returns the R code that would execute a given module command
#' @inheritParams run_modulecmd
#' @param env A character vector containing `KEY=VALUE` entries
#'  **not as a named vector** defining additional environment variables to set
#' @return An expression object containing the R code produced by this command
#' @keywords low_level
#' @export
#' @examples
#' get_module_code("purge") |> eval()
get_module_code = function(args, env = character()){
  run_modulecmd(args = args, env = env, stdout = TRUE) |> parse(text = _)
}

#' Evaluates a module command, and returns the text output.
#' @inheritParams get_module_code
#' @return A character vector with class "cli_ansi_string".
#' @keywords low_level
#' @export
#' @examples
#' get_module_output("list")
get_module_output = function(args, env = character()){
  run_modulecmd(args = args, env = env, stderr = TRUE, stdout = TRUE) |>
    `class<-`(c("cli_ansi_string", "ansi_string", "character"))
}

#' Returns a vector of currently loaded environment modules
#' @return A character vector, with one entry per module
#' @export
#' @keywords low_level
#' @examples
#' get_loaded_modules()
get_loaded_modules = function(){
  Sys.getenv("LOADEDMODULES") |> strsplit(":") |> unlist()
}
