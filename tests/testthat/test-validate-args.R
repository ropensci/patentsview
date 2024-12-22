# We can't use expect_warning() without adding a dependency to rlang 
# to bypass 8 hour warning suppression
# rlang::local_options(lifecycle_verbosity = "warning")

test_that("validate_args throws errors for all bad args", {
  skip_on_cran()

  # requesting the old plural endpoint should now throw an error
  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', endpoint = "patents"),
    "endpoint"
  )
  expect_error(
    search_pv('{"patent_date":["1976-01-06"]}', method = "Post"),
    "method"
  )
  suppressWarnings({
    result <- search_pv('{"patent_date":["1976-01-06"]}', subent_cnts = TRUE)
    # class = "lifecycle_warning_deprecated"
    expect_gt(result$query_results$total_hits, 0)
  })
  suppressWarnings({
    result <- search_pv('{"patent_date":["1976-01-06"]}', subent_cnts = 7)
    # class = "lifecycle_warning_deprecated"
    expect_gt(result$query_results$total_hits, 0)
  })
  suppressWarnings({
    result <- search_pv('{"patent_date":["1976-01-06"]}', mtchd_subent_only = NULL)
    # class = "lifecycle_warning_deprecated"
    expect_gt(result$query_results$total_hits, 0)
  })
  suppressWarnings({
    result <- search_pv('{"patent_date":["1976-01-06"]}', error_browser = "chrome")
    #class = "lifecycle_warning_deprecated"
    expect_gt(result$query_results$total_hits, 0)
  })

  per_page <- 17
  suppressWarnings({
    results <- search_pv('{"patent_date":["1976-01-06"]}', per_page = per_page)

    # make sure the size attribute was set from the per_page parameter
    expect_equal(per_page, nrow(results$data$patents))
  })

  suppressWarnings({
    result <- search_pv('{"patent_date":["1976-01-06"]}', page = 2)
    # class = "lifecycle_warning_deprecated" # unsupported page parameter
    expect_gt(result$query_results$total_hits, 0)
  })
  expect_error(
    search_pv(
      '{"patent_date":["1976-01-06"]}',
      fields = "patent_date",
      all_pages = TRUE,
      after = "3930272"
    ),
    "after"
  )
  expect_error(
    get_fields("assignee", groups = "cpc_current"), # valid group for a different endpoint
    "for the assignee endpoint"
  )
})

test_that("group names can be requested as fields via new API shorthand", {
  skip_on_cran()

  endpoint <- "patent"
  shorthand <- get_fields("patent", groups=c("application"))
  expect_equal(shorthand , "application")
  shorthand_res <- search_pv(TEST_QUERIES[[endpoint]], fields=shorthand)

  explicit <- fieldsdf[fieldsdf$endpoint == endpoint & fieldsdf$group == "application", "field"]
  explicit_res <- search_pv(TEST_QUERIES[[endpoint]], fields=explicit)

  # the requests are different but the results should be the same
  expect_failure(expect_equal(shorthand_res$request, explicit_res$request))
  expect_equal(shorthand_res$data, explicit_res$data)
  
})
