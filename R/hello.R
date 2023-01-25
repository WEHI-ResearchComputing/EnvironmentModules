

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
  {`if`}(
      !is.na(quarantine_var),
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
        }),
      ""
      )
}

get_module_command = function(args){
  c(
    "r",
    args
  ) |>
    system2(
      "/home/users/allstaff/milton.m/.conda/envs/miltonm-base/libexec/modulecmd.tcl",
      args=_,
      stdout=TRUE,
      stderr=FALSE,
    ) |>
    parse(text = _)
}

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
  }
}

link_module_libs = function(ld_library_paths, ...){
  ld_library_paths |>
    list.files(pattern = ".*\\.so", full.names = TRUE) |>
    normalizePath() |>
    unique() |>
    lapply(dyn.load, ...)
}
