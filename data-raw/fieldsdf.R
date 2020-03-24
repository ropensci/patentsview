library(rvest)
library(reshape2)
library(dplyr)
library(devtools)

endpoints <- c(
  "patent", "inventor", "assignee", "location", "cpc_subsection",
  "uspc", "nber_subcat"
)

all_tabs <- sapply(endpoints, function(x) {
  url <- paste0("https://www.patentsview.org/api/", x, ".html")
  html <- read_html(url)
  html_table(html)[[2]]
}, simplify = FALSE, USE.NAMES = TRUE)

clean_field <- function(x) gsub("[^[:alnum:]_]", "", tolower(as.character(x)))

fields <-
  melt(all_tabs) %>%
    rename(
      field = `API Field Name`, data_type = Type, can_query = Query,
      endpoint = L1, group = Group, common_name = `Common Name`,
      description = Description
    ) %>%
    select(endpoint, field, data_type, can_query, group, common_name, description) %>%
    mutate_at(vars(1:5), funs(clean_field)) %>%
    mutate(endpoint = case_when(
      .$endpoint == "patent" ~ "patents",
      .$endpoint == "inventor" ~ "inventors",
      .$endpoint == "assignee" ~ "assignees",
      .$endpoint == "location" ~ "locations",
      .$endpoint == "cpc_subsection" ~ "cpc_subsections",
      .$endpoint == "uspc" ~ "uspc_mainclasses",
      .$endpoint == "nber_subcat" ~ "nber_subcategories"
    )) %>%
    mutate(group = ifelse(group == "coinvetnros", "coinventors", group))

write.csv(fieldsdf, "data-raw/fieldsdf.csv", row.names = FALSE)
use_data(fieldsdf, internal = FALSE, overwrite = TRUE)
use_data(fieldsdf, internal = TRUE, overwrite = TRUE)
