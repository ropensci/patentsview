eps <- get_endpoints()

test_that("we can unnest all entities", {
  skip_on_cran()

  # TODO(any): add back fields = get_fields(x)
  # API throws 500s if some nested fields are included

  # locations endpoint is back but it fails this test
  bad_endpoints <- c(
    "location", "cpc_subclass",
    "uspc_subclass", "uspc_mainclass", "wipo",
    "claim", "draw_desc_text", "pg_claim"
  )
  overloaded_entities <- c("patent/rel_app_text", "publication/rel_app_text")
  good_eps <- eps[!eps %in% c(bad_endpoints, overloaded_entities)]

  z <- lapply(good_eps, function(x) {
    print(x)

    pv_out <- search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x, group = to_plural(x)) # requesting non-nested attributes
    )

    expect_gt(pv_out$query_results$total_hits, 0) # check that the query worked
    unnest_pv_data(pv_out[["data"]])
  })

  expect_true(TRUE)

  # this will fail when the api is fixed
  z <- lapply(bad_endpoints, function(x) {
    print(x)
    expect_error(
      pv_out <- search_pv(
        query = TEST_QUERIES[[x]],
        endpoint = x,
        fields = get_fields(x, group = to_plural(x)) # requesting non-nested attributes
      )
    )
  })

  # make it noticeable that all is not right with the API
  skip("Skip for API bugs") # TODO: remove when the API is fixed/bad_endpoints removed
})

test_that("endpoint's pks match their entity's pks", {
  skip_on_cran()

  # the overloaded_entities endpoints return the same entity, rel_app_texts,
  # so we can't determine the endpoint from the entity like we can
  # for the rest of the entities
  overloaded_entities <- c("patent/rel_app_text", "publication/rel_app_text")
  bad_endpoints <- c("uspc_subclass", "cpc_subclass", "uspc_mainclass", "wipo")
  good_eps <- eps[!eps %in% c(bad_endpoints, overloaded_entities)]

  endpoint_pks <- lapply(good_eps, function(endpoint) {
    print(endpoint)
    get_ok_pk(endpoint)
  })

  entity_pks <- lapply(good_eps, function(endpoint) {
    result <- search_pv(TEST_QUERIES[[endpoint]], endpoint = endpoint)
    get_ok_pk(names(result$data))
  })

  expect_equal(endpoint_pks, entity_pks)

  # this will fail when the api is fixed
  z <- lapply(bad_endpoints, function(endpoint) {
    print(endpoint)
    expect_error(
       result <- search_pv(TEST_QUERIES[[endpoint]], endpoint = endpoint)
    )
  })
})
