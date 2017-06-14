## ---- echo = FALSE, message = FALSE--------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ------------------------------------------------------------------------
query_v_1 <-
  '{"_and":[
          {"_gte":{"patent_date":"2007-03-01"}},
          {"_or":[
            {"_text_all":{"patent_title":"dog"}},
            {"_text_all":{"patent_abstract":"dog"}}
          ]},
          {"_or":[
            {"_eq":{"assingee_country":"US"}},
            {"_eq":{"assingee_country":"CA"}}
          ]}
  ]}'

## ------------------------------------------------------------------------
query_v_2 <- 
  list("_and" = 
       list(
          list("_gte" = list(patent_date = "2007-03-01")),
          list("_or" = 
                 list(
                   list("_text_all" = list(patent_title = "dog")),
                   list("_text_all" = list(patent_abstract = "dog"))
                   )
               ),
          list("_or" = 
                 list(
                   list("_eq" = list(assingee_country = "US")),
                   list("_eq" = list(assingee_country = "CA"))
                   )
               )
      )
  )

## ------------------------------------------------------------------------
library(patentsview)

query_v_3 <- 
  with_qfuns(
    and(
      gte(patent_date = "2007-03-01"),
      or(
        text_all(patent_title = "dog"),
        text_all(patent_abstract = "dog")
      ),
      eq(assingee_country = c("US", "CA"))
    )
  )

## ------------------------------------------------------------------------
jsonlite::minify(query_v_1)
jsonlite::toJSON(query_v_2, auto_unbox = TRUE)
jsonlite::toJSON(query_v_3, auto_unbox = TRUE)

## ------------------------------------------------------------------------
qry_funs$lte(assignee_total_num_inventors = 10)

## ------------------------------------------------------------------------
qry_funs$lte(cpc_subsection_id = "G12")

## ------------------------------------------------------------------------
with_qfuns(
  and(
    contains(rawinventor_first_name = "joh"),
    text_phrase(patent_abstract = c("dog bark", "cat meow")),
    not(
      text_phrase(patent_abstract = c("dog chain"))
    )
  )
)

## ------------------------------------------------------------------------
with_qfuns(
  or(
    and(
      eq(inventor_last_name = "smith"),
      text_phrase(patent_title = "cotton gin")
    ),
    and(
      eq(inventor_last_name = "hopper"),
      text_phrase(patent_title = "COBOL")
    )
  )
)

