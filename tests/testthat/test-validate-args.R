test_that("validate_args rejects invalid endpoints with endpoint error", {
  expect_error(
    search_pv('{"patent_id":"5116621"}', endpoint = "patents"),
    "endpoint must be one of the following"
  )
  expect_error(
    search_pv('{"patent_id":"5116621"}', endpoint = "not_an_endpoint"),
    "endpoint must be one of the following"
  )
})

test_that("validate_args rejects primary entity group names in fields", {
  expect_error(
    search_pv('{"patent_id":"5116621"}', endpoint = "patent", fields = "patents"),
    "Bad field\\(s\\): patents"
  )
  expect_error(
    search_pv(
      '{"patent_id":"5116621"}',
      endpoint = "patent",
      fields = c("patent_id", "patents")
    ),
    "Bad field\\(s\\): patents"
  )
  expect_error(
    search_pv(
      '{"assignee_id":"abc"}',
      endpoint = "assignee",
      fields = "assignees"
    ),
    "Bad field\\(s\\): assignees"
  )
  # Nested entity group shorthands remain allowed
  expect_null(
    validate_args(
      api_key = "test-api-key",
      fields = c("patent_id", "assignees", "inventors"),
      endpoint = "patent",
      method = "GET",
      sort = NULL,
      after = NULL,
      size = 10,
      all_pages = FALSE,
      exclude_withdrawn = NULL
    )
  )
})
