test_that("cast_pv_data casts patent fields as expected", {
  skip_on_cran()

  pv_out <- search_pv(
    query = '{"patent_id":"5116621"}', fields = get_fields("patent")
  )

  dat <- cast_pv_data(data = pv_out$data)

  # patent_date was received as a string and should be cast to a date
  date <- class(dat$patents$patent_date) == "Date"

  # patent_detail_desc_length was recieved as an int and should still be one
  num <- is.numeric(dat$patents$patent_detail_desc_length)

  # assignee type is a string like "3" from the api and gets cast to an integer
  assignee_type <- is.numeric(dat$patents$assignees[[1]]$assignee_type[[1]])

  expect_true(num && date && assignee_type)

  # application.rule_47_flag is received as a boolean and casting should leave it alone
  expect_true(is.logical(dat$patents$application[[1]]$rule_47_flag))
})

test_that("cast_pv_data casts assignee fields as expected", {
  skip_on_cran()

  # **  Invalid field: assignee_years.num_patents. assignee_years is not a nested field
  pv_out <- search_pv(
    query = '{"_text_phrase":{"assignee_individual_name_last": "Clinton"}}',
    endpoint = "assignee",
    fields = get_fields("assignee", groups = "assignees") # **
  )

  dat <- cast_pv_data(data = pv_out$data)

  # latitude comes from the api as numeric and is left as is by casting
  lat <- is.numeric(dat$assignees$assignee_lastknown_latitude[[1]])

  # here we have the same funky conversion mentioned above
  # on the field "assigneee_type"
  assignee_type <- is.numeric(dat$assignees$assignee_type[[1]])

  # was first seen date cast properly?
  cast_date <- class(dat$assignees$assignee_first_seen_date[[1]]) == "Date"

  # integer from the API should remain an integer
  years_active <- is.numeric(dat$assignees$assignee_years_active[[1]])

  expect_true(lat)
  expect_true(assignee_type)
  expect_true(cast_date)
  expect_true(years_active)

  skip("Skip for API bugs")
})

test_that("we can cast a bool", {
  skip_on_cran()

  # TODO(any): remove when the API returns this as a boolean
  fields <- c("rule_47_flag")
  endpoint <- "publication"
  results <- search_pv(query = TEST_QUERIES[[endpoint]], endpoint = endpoint, fields = fields)

  # this would fail when the API is fixed
  expect_true(is.character(results$data$publications$rule_47_flag))

  cast_results <- cast_pv_data(results$data)

  expect_true(is.logical(cast_results$publications$rule_47_flag))
})
