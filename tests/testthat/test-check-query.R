
test_that("errors are thrown on invalid queries", {
  skip_on_cran()

  expect_error(
    search_pv(qry_funs$eq("shoe_size" = 11.5)),
    "^.* is not a valid field to query for your endpoint$"
  )

  expect_error(
    search_pv(qry_funs$gt("patent_id" = "10000000")),
    "^You cannot use the operator .* with the field .*$"
  )

  expect_error(
    search_pv(qry_funs$eq("patent_date" = "10000000")),
    "^Bad date: .*\\. Date must be in the format of yyyy-mm-dd$"
  )

  expect_error(
    search_pv(qry_funs$gt("patent_id" = 10000000)),
    "^.* must be of type character$"
  )

  expect_error(
    search_pv(qry_funs$gt("patent_year" = 1980.5)),
    "^.* must be an integer$"
  )

  expect_error(
    search_pv(qry_funs$gt("patent_year" = "1980")),
    "^.* must be an integer$"
  )

  expect_error(
    search_pv(qry_funs$eq("application.rule_47_flag" = "TRUE")),
    "^.* must be a boolean$"
  )

  expect_error(
    search_pv(qry_funs$eq("rule_47_flag" = TRUE), endpoint = "publication"),
    "^.* must be of type character$"
  )

  expect_error(
    search_pv(qry_funs$gt("location_latitude" = "TRUE"), endpoint = "location"),
    "^.* must be a number$"
  )

  expect_error(
    search_pv(list(patent_number = "10000000")),
    "is not a valid operator or not a valid field"
  )

  bogus_operator_query <-
    list(
      "_ends_with" =
        list(patent_title = "dog")
    )

  expect_error(
    search_pv(bogus_operator_query),
    "is not a valid operator or not a valid field"
  )
})

test_that("a valid nested field can be queried", {
  skip_on_cran()

  results <- search_pv(qry_funs$eq("application.rule_47_flag" = FALSE))

  expect_gt(results$query_results$total_hits, 8000000)
})

test_that("the _eq message is thrown when appropriate", {
  skip_on_cran()

  expect_message(
    search_pv(list(patent_date = "2007-03-06")),
    "^The _eq operator is a safer alternative to using field:value pairs"
  )
})

test_that("a query with an and operator returns results", {
  skip_on_cran()

  patents_query <-
    with_qfuns(
      and(
        text_phrase(inventors.inventor_name_first = "George"),
        text_phrase(inventors.inventor_name_last = "Washington")
      )
    )

  result <- search_pv(patents_query)

  expect_gte(result$query_results$total_hits, 1)
})
