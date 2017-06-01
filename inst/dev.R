# rem_space <- function(str) gsub("^\\s+|\\s+$", "", str)

# remove spaces in json
# note regarding query time/timeout
# check error processing
# add warning for long get request

# figure out how rmd is rendered in github (for vig)

library(dplyr)
library(magrittr)
library(testthat)
library(patentsview)

with_qfuns(
  not(gte(patent_date = "1990-01-01"))
) -> out_pv

eps <- c("assignees", "cpc_subsections", "inventors", #"locations",
         "nber_subcategories", "patents", "uspc_mainclasses")

x <- "locations"

z <- lapply(eps, FUN = function(x) {
  search_pv("{\"patent_number\":\"5116621\"}", endpoint = x,
                 fields = get_fields(x))
  })
