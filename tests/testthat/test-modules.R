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

test_that("module_load(link_libs=TRUE) links new libaries and module_unload() unlinks them", {
  check_wehi()

  initial_libs = getLoadedDLLs()

  expect_no_error(
    suppressMessages(
      module_load("pgsql", link_libs = TRUE)
    )
  )
  expect_false(
    setequal(
      names(initial_libs),
      names(getLoadedDLLs())
    )
  )

  expect_no_error(
    suppressMessages(
      module_unload("pgsql", unlink_libs = TRUE)
    )
  )
  expect_setequal(
    names(initial_libs),
    names(getLoadedDLLs())
  )
})

test_that("module_avail() produces output", {
  module_avail() |> nzchar() |> any() |> expect_true()
})

test_that("module_list() produces output", {
  check_wehi()
  module_list() |> nzchar() |> any() |> expect_true()
})

