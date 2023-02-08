# Code relating to loading shared libraries

find_package_libs = function(package){
 find.package(package) |>
    file.path("libs") |>
    list.files(pattern = ".so$", full.names = TRUE)
}

ld_debug = function(paths, type="files"){
  # system2("ldd", paths, env=paste0("LD_DEBUG=", type), stdout=TRUE, stderr=TRUE) |>
  #   grep("calling init:", x=_, value=TRUE) |>
  #   gsub(".*\tcalling init: (.+)", "\\1", x=_) |>
  #   unique()
  system2("ldd", paths, stdout=TRUE, stderr=TRUE) |>
    # Only get absolute paths
    grep("=> /", x=_, value=TRUE) |>
    gsub(".* => (.+) .*", "\\1", x=_) |>
    normalizePath()
}

#' Title
#'
#' @param package
#'
#' @return
#' @export
#'
#' @examples
load_deps = function(package){
  package |>
    find_package_libs() |>
    ld_debug() |>
    lapply(dyn.load)
}
