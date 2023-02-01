MIN_SUPPORTED_VERSION = numeric_version("4.0.0")

#' Returns the current Environment Modules version which can be used for
#' feature testing
#' @return The current Environment Modules version as a [base::numeric_version]
#' object, or NULL if no version can be detected.
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
#'  version supported by this package.
#' @return Invisible
#' @export
#' @examples
#' check_version()
check_version = function(against = MIN_SUPPORTED_VERSION){
  version = get_version()
  if (version < MIN_SUPPORTED_VERSION || is.null(version)){
      cli::cli_abort("Your Environment Modules version is {version}, which is lower than {MIN_SUPPORTED_VERSION}, which is required for the function you just ran.")
  }
  invisible()
}

#' Gets the file path to the `modulescmd` executable
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
    cli::cli_abort("Could not detect an Environment Modules installation. Are you sure it is installed on this machine?")
  }
}

#' Runs `modulecmd` with some arguments. The shell is harcoded as "r" because
#' (surprise!) that's the language you are using right now.
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
#' @export
#' @examples
#' get_module_code("purge") |> eval()
get_module_code = function(args, env = character()){
  run_modulecmd(args = args, env = env, stdout = TRUE) |> parse(text = _)
}

#' Evaluates a module command, and returns the text output.
#' @inheritParams get_module_code
#' @return A character vector with class "cli_ansi_string". If you have the
#'  [`cli`](https://cli.r-lib.org/) package installed and loaded, it will enable enhanced
#'  printing of this result. If you don't want to install cli, you should print
#'  this result out using [base::cat()] and *not* [base::print()] to ensure the
#'  ANSI control characters are correctly displayed.
#' @export
#' @examples
#' get_module_command("list") |> cat()
get_module_output = function(args, env = character()){
  run_modulecmd(args = args, env = env, stderr = TRUE, stdout = TRUE) |>
    `class<-`(c("cli_ansi_string", "ansi_string", "character"))
}

#' Loads one or more environment modules
#' @param modules A character vector of environment modules to load
#' @param link_libs A logical scalar. If TRUE, link R to all the shared
#'  libraries contained within that module. This is not the default behaviour.
#' @param dyn_load_args An optional list of arguments to pass to [base::dyn.load()]
#'  if `link_libs` is also `TRUE`
#' @inheritParams get_module_code
#' @return A list of `DLLInfo` objects, containing the libraries (if any)
#'  that were linked. See [base::getLoadedDLLs] for an explanation of this
#'  class.
#' @export
#' @examples
#' module_load("python")
module_load = function(modules, link_libs = FALSE, dyn_load_args = list(), env = character(0)){
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
    initial_ld = strsplit(initial_ld, ":") |> unlist()
    final_ld = Sys.getenv("LD_LIBRARY_PATH") |> strsplit(":") |> unlist()
    setdiff(final_ld, initial_ld) |>
      list(ld_library_paths=_) |>
      c(dyn_load_args) |>
      do.call(link_module_libs, args=_)
  } else {
    list()
  }
}

#' Unloads one or more environment modules
#' @param modules A character vector of environment modules to unload
#' @param unlink_libs A logical scalar. If TRUE, unlink R from all the shared
#'  libraries contained within that module. This is not the default behaviour.
#' @inheritParams get_module_code
#' @return A list of `DLLInfo` objects, containing the libraries (if any)
#'  that were linked. See [base::getLoadedDLLs] for an explanation of this
#'  class.
#' @export
#' @examples
#' module_unload("python")
module_unload = function(modules, unlink_libs = FALSE, env = character(0)){
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
    initial_ld = strsplit(initial_ld, ":")
    final_ld = Sys.getenv("LD_LIBRARY_PATH") |> strsplit(":")
    setdiff(initial_ld, final_ld) |>
      do.call(link_module_libs, dyn_load_args)
    Invisible()
  } else {
    list()
  }
}

#' Lists all modules that are currently loaded
#' @return The same format as [get_module_output()]
#' @param starts_with An optional character scalar. If provided, only modules
#' whose name starts with this character string will be returned.
#' @param contains An optional character scalar. This parameter is only
#' supported in Environment Modules 4.3+. If provided, it will filter modules
#' to only those containing this substring.
#' @inheritDotParams get_module_output
#' @export
#' @examples
#' module_list() |> cat()
module_list = function(starts_with = NULL, contains = NULL, ...){
  args = c("list", starts_with)
  if (!is.null(contains)){
    args = c(args, "--contains", contains)
  }
  get_module_output(args, ...)
}

#' Unloads all modules that are currently loaded
#' @return Invisible
#' @inheritDotParams get_module_output
#' @export
#' @examples
#' module_purge()
module_purge = function(...){
  get_module_code("purge", ...) |> eval()
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
#' @inheritDotParams get_module_output
#' @inheritParams module_list
#' @export
#' @examples
#' module_avail() |> cat()
module_avail = function(starts_with = NULL, contains = NULL, ...){
  args = c("avail", starts_with)
  if (!is.null(contains)){
    args = c(args, "--contains", contains)
  }
  get_module_output(args = args, ...)
}

#' Links R to the shared libraries in a number of directories
#'
#' @param ld_library_paths A character vector indicating directories to search
#'  in.
#' @param ... Arguments forwarded to [base::dyn.load()]
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
    lapply(\(lib){
      dyn.load(lib, now=FALSE, local=FALSE) |> try()
    })
}

load_topologically = function(libs){
  deps = ldd(libs) |> suppressWarnings()
  deps = deps |>
    lapply(\(subdeps){
      names(deps) |>
        intersect(subdeps)
    })

  dep_df = data.frame(paths = libs, deps = I(deps), symbols = names(deps))

  while(TRUE){
    to_remove = lengths(dep_df$deps) == 0
    dep_df[to_remove, "paths"] |> lapply(dyn.load)
    dep_df = def_df[-to_remove, ]
  }

  lapply(libs, \(dll){
    dyn.load(dll, ..., now = FALSE, local = FALSE) |> try()
  })
}
