get_dependencies = function(binary){

}

run_ldd = function(binaries){
  system2("ldd", binaries, stdout = TRUE)
}

path_to_symbol = function(path){
  path |>
    basename() |>
    sub(".so$", "", x = _)
}

parse_ldd = function(output, binaries){
  grepl(":$", output) |>
    cumsum() |>
    split(output, f=_) |>
    lapply(\(deps){
      # Handle the fact that LDD has different output if we pass in multiple
      # binaries
      if (length(binaries) > 1){
        name = deps[[1]]
        deps = deps[-1]
      }
      else {
        name = binaries
      }

      deps |>
        strsplit("\\s") |>
        lapply(\(dep){ dep[[2]] }) |>
        unlist() |>
        # R seems to internally remove .so extensions but only at the end
        path_to_symbol() |>
        list() |>
        `names<-`(name |> sub(":$", "", x=_) |> path_to_symbol())
    }) |>
    Reduce(c, x=_)
}

ldd = function(binaries){
  run_ldd(binaries) |>
    parse_ldd(binaries)
}
