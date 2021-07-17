library(rvest)
library(reshape2)
library(dplyr)
library(devtools)

endpoints <- c(
  "assignees" = "assignees",
  "cpc_subsections" = "cpc",
  "inventors" = "inventors",
  "locations" = "locations",
  "nber_subcategories" = "nber",
  "patents" = "patents",
  "uspc_mainclasses" = "uspc"
)

all_tabs <- sapply(endpoints, function(x) {
  print(x)
  url <- paste0("https://www.patentsview.org/apis/api-endpoints/", x)
  html <- read_html(url)
  html_table(html)[[2]]
}, simplify = FALSE, USE.NAMES = TRUE)

clean_field <- function(x) gsub("[^[:alnum:]_]", "", tolower(as.character(x)))

fieldsdf <-
  melt(all_tabs) %>%
    rename(
      field = `API Field Name`, data_type = Type, can_query = Query,
      endpoint = L1, group = Group, common_name = `Common Name`,
      description = Description
    ) %>%
    select(endpoint, field, data_type, can_query, group, common_name, description) %>%
    mutate_at(vars(1:5), funs(clean_field))

write.csv(fieldsdf, "data-raw/fieldsdf.csv", row.names = FALSE)
use_data(fieldsdf, internal = FALSE, overwrite = TRUE)
use_data(fieldsdf, internal = TRUE, overwrite = TRUE)
