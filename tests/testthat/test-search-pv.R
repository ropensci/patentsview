context("search_pv")

# In the new version of the api, only three of the endpoints are searchable
# by patent number.  get_test_query() provides a sample query for each
# endpoint, except for locations, which isn't on the test server yet

# TODO: add a test to see if all the requested fields come back - to test the new
# version of the api more than to test the r packge!
T
# TODO: remove sleeps - builds are failing as they are getting throttled and search-pv doesn't
# have the throttling changes yet.  This test works locally but not when builds run in parallel

eps <- (get_endpoints())
eps <- eps[eps != "locations"]

test_that("API returns expected df names for all endpoints", {
  skip_on_cran()

  z <- vapply(eps, function(x) {
    Sys.sleep(6)
    j <- search_pv(query = get_test_query(x), endpoint = x)
    names(j[[1]])
    print(names(j[[1]]))
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)

  expect_equal(eps, z)
})

test_that("DSL-based query returns expected results", {
  skip_on_cran()

  Sys.sleep(6)
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

  expect_gt(out$query_results$total_hits, 1000)

})

test_that("search_pv can pull all fields for all endpoints", {
  skip_on_cran()

  z <- lapply(eps, function(x) {
    Sys.sleep(6)
    print(x)
    search_pv(
      query = get_test_query(x),
      endpoint = x,
      fields = get_fields(x)
    )
  })

  expect_true(TRUE)
})

# TODO: rework or remove this, subent_cnts aren't in the new version of the api
# what did the old test do?
test_that("search_pv can return subent_cnts", {
  # ...Though note this issue: https://github.com/CSSIP-AIR/PatentsView-API/issues/26
  skip_on_cran()

  Sys.sleep(6)
  out_spv <- search_pv(
    "{\"patent_number\":\"5116621\"}",
    fields = get_fields("patents", c("patents", "inventors")),
    subent_cnts = TRUE
  )
  expect_true(out_spv$query_results == 1)
})

test_that("Sort option works as expected", {
  skip_on_cran()

   # now only the assignee endpoint has lastknown_latitude
   # patent's assignee_at_grant and inventors_at_grant have a latitude 
  Sys.sleep(6)

  out_spv <- search_pv(
    qry_funs$neq(assignee_id = 1),
    fields = get_fields("assignees"),
    endpoint = "assignees",
    sort = c("lastknown_latitude" = "desc"),
    per_page = 100
  )

  lat <- as.numeric(out_spv$data$assignees$lastknown_latitude)

  expect_true(lat[1] >= lat[100])
})

# TODO: remove / rework this test - locations endpoint isn't on the test server
test_that("search_pv can pull all fields by group for the locations endpoint", {
  skip_on_cran()

  groups <- unique(fieldsdf[fieldsdf$endpoint == "locations", "group"])

  z <- lapply(groups, function(x) {
    Sys.sleep(6)

    # the locations endpoint isn't on the test server yet and probably won't be
    # queryable by patent number
    expect_error(
      search_pv(
        '{"patent_number":"5116621"}',
        endpoint = "inventors",
        fields = get_fields("inventors", x)
      )
    )
  })

  #   expect_true(TRUE)
})

test_that("search_pv properly encodes queries", {
  skip_on_cran()

  # Covers https://github.com/ropensci/patentsview/issues/24
  # need to use the assignee endpoint now and the field is full_text
  Sys.sleep(6)
  result <- search_pv(
    query = with_qfuns(
      text_phrase(organization = "Johnson & Johnson")
    ), endpoint = "assignees"
  )

  expect_true(TRUE)
})
