context("validate_args")

eps <- (get_endpoints())
eps <- eps[eps != "locations"]

test_that("we can convert endpoints to their singular form and back", {
  skip_on_cran()
  skip_on_ci()

  # the endpoints are plural so if we convert to singular and back they should be unchanged

  z <- vapply(eps, function(x) {
    # say what?  only to_singular is used by the package.  remove the others?
    to_plural(to_singular(x))
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)

  expect_equal(eps, z)
})
