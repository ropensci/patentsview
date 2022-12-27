context("utils")

test_that("we can convert endpoints to their singular form and back", {
  eps <- get_endpoints()
  z <- vapply(eps, function(x) {
    to_plural(to_singular(x))
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)
  expect_equal(eps, z)
})
