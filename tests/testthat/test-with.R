find_package_libs = function(package, ...){
  # Returns all the shared libraries in a given package
  find.package(package, ...) |>
    file.path("libs") |>
    list.files(pattern = ".so$", full.names = TRUE)
}

test_that("with_extra_modules() and with_only_modules() adjust modules as expected", {
  with_only_modules("python", {
    # Initially we should have only Python loaded
    modules = get_loaded_modules()
    expect_length(modules, 1)
    grepl("python", modules) |> expect_true()

    with_extra_modules(new = "bcftools", code = {
      # If we load bcftools on top of that, we should now have two modules loaded
      modules = get_loaded_modules()
      expect_length(modules, 2)
      grepl("python", modules) |> any() |> expect_true()
      grepl("bcftools", modules) |> any() |> expect_true()
    })
  })
})


test_that("with_module_install() correctly adjusts the RPATH of installed libraries", {
  {
    utils::install.packages("purrr")
    # Only use the temporary lib for searching for purrr
    # The RPATH header should be present in the compiled .so
    find_package_libs("purrr", lib.loc = .libPaths()[[1]]) |>
      c("-d", path=_) |>
      system2("readelf", args=_, stdout=TRUE) |>
      grepl(pattern="RPATH", x=_) |>
      any() |>
      expect_true()
  } |>
    with_only_modules("R/4.2.1", code=_) |>
    withr::with_temp_libpaths() |>
    with_module_install()
})
