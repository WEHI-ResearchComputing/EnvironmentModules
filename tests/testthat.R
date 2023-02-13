library(testthat)
library(EnvironmentModules)

options(
  repos=c(CRAN="https://cloud.r-project.org/")
)

test_check("EnvironmentModules")
