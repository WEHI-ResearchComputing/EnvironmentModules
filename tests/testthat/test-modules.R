check_wehi = function(){
  system2("hostname", stdout = TRUE) |>
    grepl("wehi.edu.au", x=_) |>
    skip_if_not()
}

test_that("get_version() returns the correct version", {
  check_wehi()
  expect_equal(
    get_version(),
    numeric_version("5.2.0")
  )
})

test_that("check_version() compares correctly", {
  check_wehi()

  expect_error(
    check_version("6.0.0")
  )

  expect_no_error(
    check_version("5.0.0")
  )
})

test_that("get_modulescmd_binary() returns the right path", {
  check_wehi()

  expect_true(
    get_modulescmd_binary() |> file.exists()
  )
})

test_that("get_module_code() returns code that can be run", {
  check_wehi()

  code = get_module_code(c("load", "gh-cli"))

  expect_type(code, "expression")
  expect_gt(length(code), 1)
})

test_that("get_module_output() returns text output", {
  check_wehi()

  output = get_module_output(c("avail"))

  expect_s3_class(output, "cli_ansi_string")
  expect_gt(length(output), 1)
  output |> nzchar() |> any() |> expect_true()
})

test_that("module_load() adjusts the environment and module_unload() resets it", {
  check_wehi()

  initial_env = Sys.getenv()

  expect_no_error(
    suppressMessages(
      module_load("gh-cli")
    )
  )
  expect_false(
    setequal(initial_env, Sys.getenv())
  )

  expect_no_error(
    module_unload("gh-cli")
  )
  expect_true(
    setequal(initial_env, Sys.getenv())
  )
})

test_that("module_swap() works", {
  check_wehi()
  initial_env = Sys.getenv("LD_LIBRARY_PATH")
  suppressMessages(
    module_swap("proj/4.9.3", "proj/6.3.2")
  )
  expect_gt(
    diff_libs(initial_env, Sys.getenv("LD_LIBRARY_PATH")) |> length(),
    0
  )
  suppressMessages(
    module_swap("proj/6.3.2", "proj/4.9.3")
  )
  expect_equal(
    diff_libs(initial_env, Sys.getenv("LD_LIBRARY_PATH")),
    character()
  )
})

test_that("module_list() works", {
  check_wehi()

  module_purge()
  module_load("python", "bcftools")
  loaded = module_list()
  expect_length(loaded, 2)
  grepl("python", loaded) |> any() |> expect_true()
  grepl("bcftools", loaded) |> any() |> expect_true()
  module_unload("python", "bcftools")
})

test_that("module_avail() works", {
  check_wehi()

  module_avail() |> length() |> expect_gt(500)
})

test_that("module_load() throws an error on failure", {
  check_wehi()

  module_load("NOT_A_REAL_MODULE") |> expect_error("Failed to load")
})
