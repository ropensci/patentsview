context("search_pv")

eps <- get_endpoints()

test_that("API returns expected df names for all endpoints", {
  skip_on_cran()
  skip_on_ci()

  z <- vapply(eps, function(x) {
    Sys.sleep(3)
    j <- search_pv("{\"patent_number\":\"5116621\"}", endpoint = x)
    names(j[[1]])
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)

  expect_equal(eps, z)
})

test_that("DSL-based query returns expected results", {
  skip_on_cran()
  skip_on_ci()

  query <- with_qfuns(
    and(
      or(
        gte(patent_date = "2014-01-01"),
        lte(patent_date = "1978-01-01")
      ),
      text_phrase(patent_abstract = c("computer program", "dog leash"))
    )
  )

  out <- search_pv(query)

  expect_gt(out$query_results$total_patent_count, 1000)
})

test_that("search_pv can pull all fields for all endpoints except locations", {
  skip_on_cran()
  skip_on_ci()

  eps_no_loc <- eps[eps != "locations"]

  z <- lapply(eps_no_loc, function(x) {
    Sys.sleep(3)
    search_pv(
      "{\"patent_number\":\"5116621\"}",
      endpoint = x,
      fields = get_fields(x)
    )
  })

  expect_true(TRUE)
})

test_that("search_pv can return subent_cnts", {
  # ...Though note this issue: https://github.com/CSSIP-AIR/PatentsView-API/issues/26
  skip_on_cran()
  skip_on_ci()

  out_spv <- search_pv(
    "{\"patent_number\":\"5116621\"}",
    fields = get_fields("patents", c("patents", "inventors")),
    subent_cnts = TRUE
  )
  expect_true(length(out_spv$query_results) == 2)
})

test_that("Sort option works as expected", {
  skip_on_cran()
  skip_on_ci()

  out_spv <- search_pv(
    qry_funs$gt(patent_date = "2015-01-01"),
    fields = get_fields("inventors", c("inventors")),
    endpoint = "inventors",
    sort = c("inventor_lastknown_latitude" = "desc"),
    per_page = 100
  )

  lat <- as.numeric(out_spv$data$inventors$inventor_lastknown_latitude)

  expect_true(lat[1] >= lat[100])
})

test_that("search_pv can pull all fields by group for the locations endpoint", {
  skip_on_cran()
  skip_on_ci()

  groups <- unique(fieldsdf[fieldsdf$endpoint == "locations", "group"])

  z <- lapply(groups, function(x) {
    Sys.sleep(3)
    search_pv(
      '{"patent_number":"5116621"}',
      endpoint = "inventors",
      fields = get_fields("inventors", x)
    )
  })

   expect_true(TRUE)
})

test_that("search_pv properly encodes queries", {
  skip_on_cran()
  skip_on_ci()

  # Covers https://github.com/ropensci/patentsview/issues/24
  result <- search_pv(
    query = with_qfuns(
      begins(assignee_organization = "Johnson & Johnson")
    )
  )

  expect_true(TRUE)
})
