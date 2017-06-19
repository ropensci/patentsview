params <-
structure(list(eval_all = TRUE), .Names = "eval_all")

## ---- echo = FALSE, message = FALSE--------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----eval = FALSE--------------------------------------------------------
#  devtools::install_github("ropensci/patentsview")

## ------------------------------------------------------------------------
library(patentsview)

search_pv(query = '{"_gte":{"patent_date":"2007-01-01"}}',
          endpoint = "patents")

## ------------------------------------------------------------------------
search_pv(query = '{"_gte":{"patent_date":"2007-01-01"}}',
          endpoint = "patents", 
          fields = c("patent_number", "patent_title"))

## ------------------------------------------------------------------------
retrvble_flds <- get_fields(endpoint = "patents")
head(retrvble_flds)

## ------------------------------------------------------------------------
qry_funs$gte(patent_date = "2007-01-01")

## ------------------------------------------------------------------------
with_qfuns(
  and(
    gte(patent_date = "2007-01-01"),
    text_phrase(patent_abstract = c("computer program", "dog leash"))
  )
)

## ----eval = params$eval_all----------------------------------------------
search_pv(query = qry_funs$eq(inventor_last_name = "chambers"),
          page = 2, per_page = 150) # gets records 150 - 300

## ----eval = params$eval_all----------------------------------------------
search_pv(query = qry_funs$eq(inventor_last_name = "chambers"),
          all_pages = TRUE)

## ------------------------------------------------------------------------
# Here we are using the patents endpoint
search_pv(query = qry_funs$eq(inventor_last_name = "chambers"), 
          endpoint = "patents", 
          fields = c("patent_number", "inventor_last_name", 
                     "assignee_organization"))

## ------------------------------------------------------------------------
# While here we are using the assignees endpoint
search_pv(query = qry_funs$eq(inventor_last_name = "chambers"), 
          endpoint = "assignees", 
          fields = c("patent_number", "inventor_last_name", 
                     "assignee_organization"))

## ----eval = params$eval_all----------------------------------------------
search_pv(query = qry_funs$gt(patent_num_cited_by_us_patents = 500))

## ----eval = params$eval_all----------------------------------------------
# Setting subent_cnts = TRUE will give us the subentity counts. Since inventors 
# are subentities for the patents endpoint, this means we will get their counts.
search_pv(query = qry_funs$gt(patent_num_cited_by_us_patents = 500),
          fields = c("patent_number", "inventor_id"), subent_cnts = TRUE)

## ----eval = params$eval_all----------------------------------------------
query <- with_qfuns(
  and(
    gte(patent_date = "2010-01-01"),
    contains(assignee_organization = "microsoft")
  )
)
search_pv(query = query)

## ----eval = params$eval_all----------------------------------------------
# Get all possible retrievable assignee-level and patent-level fields for 
# the assignees endpoint:
asgn_pat_flds <- get_fields("assignees", c("assignees", "patents"))

# Ask the PatentsView API for these fields:
search_pv(query = qry_funs$contains(inventor_last_name = "smith"), 
          endpoint = "assignees", fields = asgn_pat_flds)

## ----eval = params$eval_all----------------------------------------------
search_pv(query = qry_funs$contains(govint_org_name = "department of energy"), 
          endpoint = "cpc_subsections", 
          fields =  "cpc_total_num_patents",
          sort = c("cpc_total_num_patents" = "desc"), 
          per_page = 10)

## ------------------------------------------------------------------------
query <- with_qfuns(
  text_any(patent_abstract = 'tool animal')
)

## ------------------------------------------------------------------------
query_1a <- with_qfuns(
  and(
    text_any(patent_abstract = 'tool animal'),
    lte(patent_date = "2010-01-01")
  )
)

query_1b <- with_qfuns(
  and(
    text_any(patent_abstract = 'tool animal'),
    gt(patent_date = "2010-01-01")
  )
)

## ------------------------------------------------------------------------
res <- search_pv(query = qry_funs$contains(inventor_last_name = "smith"), 
                 endpoint = "assignees", 
                 fields = get_fields("assignees", c("assignees","applications", 
                                                    "gov_interests")))
res$data

## ------------------------------------------------------------------------
unnest_pv_data(data = res$data, pk = "assignee_id")

