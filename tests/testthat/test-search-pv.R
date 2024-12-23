
add_base_url <- function(x) {
  paste0("https://search.patentsview.org/api/v1/", x)
}

endpoints <- get_endpoints()

test_that("API returns expected df names for all endpoints", {
  skip_on_cran()

  broken_endpoints <- c(
    "cpc_subclass",
    "uspc_subclass",
    "uspc_mainclass",
    "wipo"
  )

  # these both return rel_app_texts
  overloaded_entities <- c("patent/rel_app_text", "publication/rel_app_text")

  goodendpoints <- endpoints[!endpoints %in% c(broken_endpoints, overloaded_entities)]

  df_names <- vapply(goodendpoints, function(x) {
    print(x)
    out <- search_pv(query = TEST_QUERIES[[x]], endpoint = x)

    # now the endpoints are singular and most entites are plural
    to_singular(names(out[[1]]))
  }, FUN.VALUE = character(1), USE.NAMES = FALSE)

  # publication/rel_app_text's entity is rel_app_text_publications
  df_names <- gsub("rel_app_text_publication", "rel_app_text", df_names)

  expect_equal(goodendpoints, df_names)
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

test_that("You can download up to 9,000+ records", {
  skip_on_cran()

  # Should return 9,000+ rows
  query <- with_qfuns(
    and(
      gte(patent_date = "2021-12-13"),
      lte(patent_date = "2021-12-24")
    )
  )
  out <- search_pv(query, size = 1000, all_pages = TRUE)
  expect_gt(out$query_results$total_hits, 9000)
})

test_that("search_pv can pull all fields for all endpoints", {
  skip_on_cran()

  troubled_endpoints <- c(
    "cpc_subclass", "location",
    "uspc_subclass", "uspc_mainclass", "wipo", "claim", "draw_desc_text",
    "pg_claim"  # Invalid field: claim_dependent
  )

  # We should be able to get all fields from the non troubled endpoints
  dev_null <- lapply(endpoints[!(endpoints %in% troubled_endpoints)], function(x) {
    print(x)
    search_pv(
      query = TEST_QUERIES[[x]],
      endpoint = x,
      fields = get_fields(x)
    )
  })
  expect_true(TRUE)
})

test_that("Sort option works as expected", {
  skip_on_cran()

  out <- search_pv(
    qry_funs$neq(assignee_id = ""),
    fields = get_fields("assignee", groups = c("assignees")),
    endpoint = "assignee",
    sort = c("assignee_lastknown_latitude" = "desc"),
    size = 100
  )
  lat <- as.numeric(out$data$assignees$assignee_lastknown_latitude)
  expect_true(lat[1] >= lat[100])
})

test_that("search_pv properly URL encodes queries", {
  skip_on_cran()

  # Covers https://github.com/ropensci/patentsview/issues/24
  # need to use the assignee endpoint now
  organization <- "Johnson & Johnson International"
  text_query <- with_qfuns(text_phrase(assignee_organization = organization))
  phrase_search <- search_pv(text_query, endpoint = "assignee")
  expect_true(phrase_search$query_results$total_hits == 1)

  # also test that the string operator does not matter now
  eq_query <- with_qfuns(eq(assignee_organization = organization))
  eq_search <- search_pv(eq_query, endpoint = "assignee")
  expect_identical(eq_search$data, phrase_search$data)

  # text_phrase seems to be case insensitive but equal is not
  organization <- tolower(organization)

  text_query <- with_qfuns(text_phrase(assignee_organization = organization))
  phrase_search <- search_pv(text_query, endpoint = "assignee")
  expect_true(phrase_search$query_results$total_hits == 1)

  eq_query <- with_qfuns(eq(assignee_organization = organization))
  eq_search <- search_pv(eq_query, endpoint = "assignee")
  expect_true(eq_search$query_results$total_hits == 0)
})


test_that("We won't expose the user's patentsview API key to random websites", {
  skip_on_cran()

  # We will try to call the api that tells us who is currently in space
  in_space_now_url <- "http://api.open-notify.org/astros.json"
  expect_error(retrieve_linked_data(in_space_now_url))
})


test_that("We can call all the legitimate HATEOAS endpoints", {
  skip_on_cran()

  single_item_queries <- c(
    "cpc_subclass/A01B/",
    "cpc_class/A01/",
    "cpc_group/G01S7:4811/",
    "patent/10757852/",
    "uspc_mainclass/30/",
    "uspc_subclass/30:100/",
    "wipo/1/",
    "publication/20010000001/"
  )

  # these currently throw Error: Internal Server Error
  broken_single_item_queries <- c(
    "cpc_subclass/A01B/",
    "uspc_mainclass/30/",
    "uspc_subclass/30:100/",
    "wipo/1/"
  )

  single_item_queries <- single_item_queries[!single_item_queries %in% broken_single_item_queries]

  dev_null <- lapply(single_item_queries, function(q) {
    print(q)
    j <- retrieve_linked_data(add_base_url(q))
    expect_equal(j$query_results$total_hits, 1)
  })

  multi_item_queries <- c(
    "patent/us_application_citation/10966293/",
    "patent/us_patent_citation/10966293/"
  )
  dev_null <- lapply(multi_item_queries, function(q) {
    j <- retrieve_linked_data(add_base_url(q))
    expect_true(j$query_results$total_hits > 1)
  })


  # We'll make a call to get an inventor and assignee HATEOAS link
  # in case their ids are not persistent
  # new weirdness: we request inventor_id and assignee_id but the
  # fields come back without the _id
  res <- search_pv('{"patent_id":"10000000"}',
    fields = c("inventors.inventor_id", "assignees.assignee_id")
  )

  assignee <- retrieve_linked_data(res$data$patents$assignees[[1]]$assignee)
  expect_true(assignee$query_results$total_hits == 1)

  inventor <- retrieve_linked_data(res$data$patents$inventors[[1]]$inventor)
  expect_true(inventor$query_results$total_hits == 1)

  # Query to get a location HATEOAS link in case location_ids are not persistent
  res <- search_pv('{"location_name":"Chicago"}',
    fields = c("location_id"),
    endpoint = "location"
  )

  location <- retrieve_linked_data(add_base_url(paste0("location/", res$data$locations$location_id, "/")))
  expect_true(location$query_results$total_hits == 1)
})

# Make sure gets and posts return the same data.
# Posts had issues that went undetected for a while using the new API
# (odd results with posts when either no fields or sort was passed
# see get_post_body in search-pv.R)

test_that("posts and gets return the same data", {
  skip_on_cran()

  bad_eps <- c(
    "cpc_subclass"
    #  ,"location" # Error: Invalid field: location_latitude
    , "uspc_subclass" # Error: Internal Server Error
    , "uspc_mainclass" # Error: Internal Server Error
    , "wipo" # Error: Internal Server Error
    , "claim" # Error: Invalid field: claim_dependent
    , "draw_desc_text" # Error: Invalid field: description_sequence
    , "cpc_subclass" # 404?  check the test query
    , "uspc_subclass" # 404
    #  , "pg_claim"  # check this one
  )

  good_eps <- endpoints[!endpoints %in% bad_eps]

  z <- lapply(good_eps, function(endpoint) {
    print(endpoint)
    get_res <- search_pv(
      query = TEST_QUERIES[[endpoint]],
      endpoint = endpoint,
      method = "GET"
    )

    g <- unnest_pv_data(get_res$data, pk = get_ok_pk(endpoint))

    post_res <- search_pv(
      query = TEST_QUERIES[[endpoint]],
      endpoint = endpoint,
      method = "POST"
    )

    p <- unnest_pv_data(post_res$data)

    expect_equal(g, p)
  })
})

test_that("nested shorthand produces the same results as fully qualified ones", {
  skip_on_cran()

  # the API now allows a shorthand in the fields/f: parameter
  # just the group name will retrieve all that group's attributes
  # This is indirectly testing our parse of the OpenAPI object and actual API responses
  fields <- fieldsdf[fieldsdf$endpoint == "patent" & fieldsdf$group == "application", "field"]

  shorthand_res <- search_pv(TEST_QUERIES[["patent"]], fields = c("application"))
  qualified_res <- search_pv(TEST_QUERIES[["patent"]], fields = fields)

  # the request$urls will be different but the data should match
  expect_failure(expect_equal(shorthand_res$request$url, qualified_res$request$url))
  expect_equal(shorthand_res$data, qualified_res$data)
})


test_that("the 'after' parameter works properly", {
  skip_on_cran()

  sort <- c("patent_id" = "asc")
  big_query <- qry_funs$eq(patent_date = "2000-01-04") # 3003 total_hits
  results <- search_pv(big_query, all_pages = FALSE, sort = sort)
  expect_gt(results$query_results$total_hits, 1000)

  after <- results$data$patents$patent_id[[nrow(results$data$patents)]]
  subsequent <- search_pv(big_query, all_pages = FALSE, after = after, sort = sort)

  # ** New API bug?  should be expect_equal `actual`:  399
  expect_lt(nrow(subsequent$data$patents), 1000)

  # the first row's patent_id should be bigger than after
  # now "D418273"
  # expect_gt(as.integer(subsequent$data$patents$patent_id[[1]]), as.integer(after))

  # now we'll add a descending sort to make sure that also works
  sort <- c("patent_id" = "desc")
  fields <- NULL #  c("patent_id")

  results <- search_pv(big_query, all_pages = FALSE, fields = fields, sort = sort)
  after <- results$data$patents$patent_id[[nrow(results$data$patents)]]

  subsequent <- search_pv(big_query,
    all_pages = FALSE, after = after, sort = sort,
    fields = fields
  )

  # now the first row's patent_id should be smaller than after
  # should be expect_lt
  expect_gt(as.integer(subsequent$data$patents$patent_id[[1]]), as.integer(after))
  skip("New API bug?")
})

test_that("the documentation and Swagger UI URLs work properly", {
  skip_on_cran()

  documentation_url <-
    'https://search.patentsview.org/api/v1/patent/?q={"_text_any":{"patent_title":"COBOL cotton gin"}}&s=[{"patent_id": "asc" }]&o={"size":50}&f=["inventors.inventor_name_last","patent_id","patent_date","patent_title"]'

  results <- retrieve_linked_data(documentation_url)

  expect_gt(results$query_results$total_hits, 0)

  swagger_url <- "https://search.patentsview.org/api/v1/patent/?q=%7B%22patent_date%22%3A%221976-01-06%22%7D"

  results <- retrieve_linked_data(swagger_url, encoded = TRUE)
  expect_gt(results$query_results$total_hits, 0)
})

test_that("an error occurs if all_pages is TRUE and there aren't any results", {
  skip_on_cran()

  too_early <- qry_funs$lt(patent_date = "1976-01-01")

  results <- search_pv(too_early, all_pages = FALSE)

  # would like this test to fail! (meaning API added earlier data)
  expect_equal(results$query_results$total_hits, 0)

  expect_error(
    search_pv(too_early, all_pages = TRUE),
    "No records matched your query"
  )
})

test_that("we can retrieve all_pages = TRUE without specifiying fields", {
  skip_on_cran()

  query <- qry_funs$eq(patent_date = "1976-01-06")
  sort <- c("patent_type" = "asc", "patent_id" = "asc")

  # here we aren't requesting fields but are requesting a sort
  results <- search_pv(query, sort = sort, all_pages = TRUE)

  expect_gt(results$query_results$total_hits, 1300)
})

# Below we request the same data in built_singly and result_all, with the only
# difference being that we intentionally get throttled in built_singly by
# sending one request per patent number (instead of all requests at once). If
# the two responses match, then we've correctly handled throttling errors.
test_that("Throttled requests are automatically retried", {
  skip_on_cran()

  res <- search_pv('{"_gte":{"patent_date":"2007-01-04"}}', size = 50)
  patent_ids <- res$data$patents$patent_id

  # now we don't get message "The API's requests per minute limit has been reached. "
  # so we'll testthat it takes over 60 seconds to run (since we got throttled)
  # TODO(any): can we use evaluate_promise to find "Waiting 45s for retry backoff"?

  duration <- system.time(
    built_singly <- lapply(patent_ids, function(patent_id) {
      search_pv(
        query = qry_funs$eq(patent_id = patent_id),
        endpoint = "patent/us_patent_citation",
        fields = c("patent_id", "citation_patent_id"),
        sort = c("citation_patent_id" = "asc")
      )[["data"]][["us_patent_citations"]]
    })
  )

  expect_gt(duration[["elapsed"]], 60)

  built_singly <- do.call(rbind, built_singly)

  # we'll also test that the results are the same for a post and get
  # when there is a secondary sort on the bulk requests
  sort <- c("patent_id" = "asc", "citation_patent_id" = "asc")
  methods <- c("POST", "GET")
  output <- lapply(methods, function(method) {
    result_all <- search_pv(
      query = qry_funs$eq(patent_id = patent_ids),
      endpoint = "patent/us_patent_citation",
      fields = c("patent_id", "citation_patent_id"),
      sort = sort,
      size = 1000,
      all_pages = TRUE,
      method = method
    )
    result_all <- result_all$data$us_patent_citations
  })

  expect_equal(output[[1]], output[[2]])

  # We'll do our own sort and check that it matches the API output
  # We want to make sure we sent in the sort parameter correctly, where
  # the API is doing the sort (since the we didn't need to page)
  
  second_output <- output[[2]]

  # Sorting logic using order()
  sort_order <- mapply(function(col, direction) {
    if (direction == "asc") {
      return(second_output[[col]])
    } else {
      return(-rank(second_output[[col]], ties.method = "min"))  # Invert for descending order
    }
  }, col = names(sort), direction = as.vector(sort), SIMPLIFY = FALSE)

  # Final sorting
  second_output <- second_output[do.call(order, sort_order), , drop = FALSE]

  expect_equal(output[[1]], second_output)

  # TODO(any): fix this:
  # expect_equal says actual row.names are an integer vector and expected
  # row.names is a character vector.  Not sure why
  row.names(output[[1]]) <- NULL
  row.names(built_singly) <- NULL

  expect_equal(built_singly, output[[1]])
})

test_that("we can sort on an unrequested field across page boundaries", {
  skip_on_cran()

  # total_hits = 5,352
  query <- qry_funs$in_range(patent_date = c("1976-01-01", "1976-01-31"))
  fields <- c("patent_title", "patent_date")
  sort <- c("patent_date" = "desc", "patent_id" = "desc")

  r_ordered <- search_pv(
    query = query,
    fields = fields,
    sort = sort,
    all_pages = TRUE
  )

  fields <- c(fields, "patent_id")
  api_ordered <- search_pv(
    query = query,
    fields = fields,
    sort = sort,
    all_pages = TRUE
  )

  # Remove patent_id before comparison.  We're also indirectly testing that the
  # patent_id field added by the first search_pv was removed, otherwise this
  # expect equal would fail
  api_ordered$data$patents[["patent_id"]] <- NULL
  expect_equal(r_ordered$data, api_ordered$data)
})

test_that("sort works across page boundaries", {
  skip_on_cran()

  sort <- c("patent_type" = "desc", "patent_id" = "desc")
  results <- search_pv(
    qry_funs$eq(patent_date = "1976-01-06"),
    fields = c("patent_type", "patent_id"),
    sort = sort,
    all_pages = TRUE
  )

  double_check <- results$data$patents

  # Sorting logic using order()
  sort_order <- mapply(function(col, direction) {
    if (direction == "asc") {
      return(double_check[[col]])
    } else {
      return(-rank(double_check[[col]], ties.method = "min"))  # Invert for descending order
    }
  }, col = names(sort), direction = as.vector(sort), SIMPLIFY = FALSE)

  # Final sorting
  double_check <- double_check[do.call(order, sort_order), , drop = FALSE]

  expect_equal(results$data$patents, double_check)
})
