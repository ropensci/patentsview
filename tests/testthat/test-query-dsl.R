test_that("between works as expected", {
  skip_on_cran()

  query <- qry_funs$in_range(patent_date = c("1976-01-06", "1976-01-13"))

  results <- search_pv(query, all_pages = TRUE)

  expect_gt(results$query_results$total_hits, 2600)
})

test_that("with_qfuns() works as advertised", {
  skip_on_cran() # wouldn't necessarily have to skip!

  a <- with_qfuns(
    and(
      text_phrase(inventors.inventor_name_first = "George"),
      text_phrase(inventors.inventor_name_last = "Washington")
    )
  )

  b <- qry_funs$and(
    qry_funs$text_phrase(inventors.inventor_name_first = "George"),
    qry_funs$text_phrase(inventors.inventor_name_last = "Washington")
  )

  expect_equal(a, b)
})

test_that("argument check works on in_range", {
  skip_on_cran() # wouldn't necessarily have to skip!

  expect_error(
    qq <- qry_funs$in_range("patent_id", c("10000000", "10000002")),
    "expects a range of exactly two arguments"
  )
})
