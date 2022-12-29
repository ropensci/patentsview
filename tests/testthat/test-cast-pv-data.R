context("cast_pv_data")

test_that("cast_pv_data casts data types as expected", {
  skip_on_cran()
  # TODO(any): Remove:
  skip("Temp skip for API redesign PR")

  pv_out <- search_pv(
    query = "{\"patent_id\":\"5116621\"}", fields = get_fields("patents")
  )

  dat <- cast_pv_data(data = pv_out$data)

  date <- !is.character(dat$patents$patent_date)
  num <- is.numeric(dat$patents$patent_num_claims)
  date2 <- !is.character(dat$patents$assignees[[1]]$assignee_last_seen_date[1])

  expect_true(date && num && date2)
})
