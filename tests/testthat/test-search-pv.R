context("search_pv")

# In the new version of the api, only three of the endpoints are searchable
# by patent number.  get_test_query() provides a sample query for each
# endpoint, except for locations, which isn't on the test server yet

# TODO: add a test to see if all the requested fields come back - to test the new
# version of the api more than to test the r packge!

eps <- (get_endpoints())
eps <- eps[eps != "locations"]

test_that("API returns expected df names for all endpoints", {
  skip_on_cran()

  z <- vapply(eps, function(x) {
    j <- search_pv(query = get_test_query(x), endpoint = x)
    names(j[[1]])
    print(names(j[[1]]))
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)

  expect_equal(eps, z)
})

test_that("DSL-based query returns expected results", {
  skip_on_cran()

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
  result <- search_pv(
    query = with_qfuns(
      text_phrase(organization = "Johnson & Johnson")
    ), endpoint = "assignees"
  )

  expect_true(TRUE)
})

test_that("throttled requests are automatically retried", {
  skip_on_cran()
  skip_on_ci()

  # See if we can get throttled!  We'll ask for 50 patent numbers and then call back
  # for the citations of each - the new version of the api doesn't return citations
  # from the patent endpoint.  This would be a semi legitimate use case though we'd probably
  # call back for all the patents or groups of patents, rather than individually.

  res <- search_pv(
    '{"_gte":{"patent_date":"2007-01-04"}}',
    per_page = 50
  )

  dl <- unnest_pv_data(res$data, "patent_number")

  # Fire off the individual requests as fast as we can - the api should throttle us if we make
  # more than 45 requests per minute.  The throttling reply contains a header
  # of how many seconds to wait before retrying the request.  We're testing that search_pv
  # handles this for us.

  # Currently there is a commented out warning in search-pv when throttling occurs.
  # Possibly add a new argument to suppress the warning, defaulted to true.  We could set it 
  # to false here and do an expect_warning() here

  # We'll combine the output of the 50 calls
  built_singly <- data.frame()

  for (i in 1:length(dl$patents$patent_number))
  {
    query <- qry_funs$eq(patent_number = dl$patents$patent_number[i])

    res2 <- search_pv(
      query = query,
      endpoint = "patent_citations",
      fields = c("patent_number", "cited_patent_number"),
      sort = c("cited_patent_number" = "asc"),
       per_page = 1000 # new maximum
     )

    built_singly <- rbind(built_singly, res2$data$patent_citations)
  }

  # Now we want to make a single call to get the same data and
  # assert that the bulk results match the list of individual calls -
  # to prove that the throttled call eventually went through properly

  query_all <- qry_funs$eq(patent_number = dl$patents$patent_number)

  result_all <- search_pv(
    query = query_all,
    fields = c("patent_number", "cited_patent_number"),
    endpoint = "patent_citations",
    sort = c("patent_number" = "asc", "cited_patent_number" = "asc"),
    per_page = 1000, # new maximum
    all_pages = TRUE # would there be more than one page of results?
  )

  all <- unnest_pv_data(result_all$data, "patent_number")

  expect_identical(all$patent_citations, built_singly)
})
