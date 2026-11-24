# These tests verify known API bugs/quirks.
# Run live from time to time, when a test fails, the bug 
# may be fixed - verify and remove the workaround.

# --- Extra fields returned bug ---
# API returns more fields than requested, can break paging with rbind.
# Workaround: repair_resp() strips unrequested fields (process-resp.R:54)

test_that("API returns extra fields not requested", {
  skip_on_cran()

  vcr::local_cassette("bug-extra-fields-returned")
  # Bypass repair_resp() by using retrieve_linked_data()
  url <- paste0(
    get_base("patent"),
    "?q=%7B%22patent_id%22%3A%225116621%22%7D",
    "&f=%5B%22patent_id%22%5D&s=&o=%7B%22size%22%3A1000%7D"
  )

  res <- retrieve_linked_data(url)
  returned <- names(res$data[[1]])

  # Should only get patent_id, but API returns more
  extra <- setdiff(returned, "patent_id")
  # Test fails when bug is fixed - then remove repair_resp() workaround
  expect_true(
    length(extra) > 0,
    label = "Bug may be fixed - check repair_resp() workaround"
  )
})

# --- Unadvertised fields bug ---
# Some endpoints return fields not in openapi.json spec.

test_that("patent/foreign_citation returns unadvertised 'patent' field", {
  skip_on_cran()

  vcr::local_cassette("bug-unadvertised-fields")
  res <- search_pv(
    '{"patent_id": "10000001"}',
    endpoint = "patent/foreign_citation",
    fields = get_fields("patent/foreign_citation")
  )

  fields <- get_fields("patent/foreign_citation")
  # Bypass repair_resp() by using retrieve_linked_data()
  url <- paste0(
    sub("/$", "", get_base("patent/foreign_citation")),
    "?q=%7B%22patent_id%22%3A%2210000001%22%7D",
    "&f=", URLencode(jsonlite::toJSON(fields)),
    "&s=&o=%7B%22size%22%3A1000%7D"
  )

  raw <- retrieve_linked_data(url)
  returned <- names(raw$data[[1]])
  advertised <- get_fields("patent/foreign_citation")

  extra <- setdiff(returned, advertised)
  expect_true("patent" %in% extra)
})

# --- Case sensitivity bug (PVS-1147) ---
# String equality is case-sensitive, unlike the old API.

test_that("string equals is case sensitive (PVS-1147)", {
  skip_on_cran()

  vcr::local_cassette("bug-case-sensitivity")
  # Exact case works
  res <- search_pv(
    qry_funs$eq(assignee_organization = "Johnson & Johnson International"),
    endpoint = "assignee"
  )
  expect_equal(res$query_results$total_hits, 1)

  # Lowercase returns nothing
  res <- search_pv(
    qry_funs$eq(assignee_organization = "johnson & johnson international"),
    endpoint = "assignee"
  )
  expect_equal(res$query_results$total_hits, 0)
})

# --- publication rule_47_flag bug (PVS-1884) ---

test_that("publication rule_47_flag query inverted (PVS-1884)", {
  skip_on_cran()

  vcr::local_cassette("bug-publication-rule-47")
  # FALSE should return results but returns 0
  res <- search_pv(
    qry_funs$eq(rule_47_flag = FALSE),
    endpoint = "publication"
  )
  expect_equal(res$query_results$total_hits, 0)
})

# --- IPC endpoint field bug ---
# The ipc endpoint returns HTTP 500 when requesting only the primary key (ipc_id).
# Works fine when requesting all fields.

test_that("ipc endpoint fails with default fields (only ipc_id)", {
  skip_on_cran()

  vcr::local_cassette("bug-ipc-500")
  # When no fields specified, search_pv() adds only the primary key ipc_id
  # This triggers a 500 error from the API
  expect_error(
    search_pv('{"ipc_id": "1"}', endpoint = "ipc"),
    regexp = "500|Internal Server Error"
  )
})

# --- Paging structure mismatch bug ---
# Some queries return different fields on different pages, breaking rbind.
# Workaround: stop() with clear error message in search-pv.R

test_that("paging returns inconsistent fields (structure mismatch)", {
  skip_on_cran()

  vcr::local_cassette("bug-paging-inconsistency")
  # This query is known to return different fields across pages
  query <- with_qfuns(
    and(
      gte(patent_earliest_application_date = "2001-01-01"),
      eq(cpc_current.cpc_subclass_id = "B62K"),
      eq(assignees.assignee_country = "US")
    )
  )

  # Request all fields - some pages return uspc_at_issue, others don't
  fields <- get_fields("patent")

  # Test fails when bug is fixed - then the stop() workaround can be removed

  expect_error(
    search_pv(query, fields = fields, all_pages = TRUE),
    regexp = "API returned paged data with different structure"
  )
})

