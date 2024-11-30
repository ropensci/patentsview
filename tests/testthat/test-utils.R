context("utils")

test_that("we can convert endpoints to their plural form and back", {
  skip_on_cran()

  eps <- get_endpoints()
  z <- vapply(eps, function(x) {
    to_singular(to_plural(x))
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)

  # we now need to unnest the endpoints for the comparison to work
  unnested_eps <- gsub("^(patent|publication)/", "", eps)

  expect_equal(unnested_eps, z)
})
