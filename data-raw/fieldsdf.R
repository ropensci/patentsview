library(XML)
library(reshape2)
library(dplyr)
library(devtools)

c("patent","inventor", "assignee", "location",
  "cpc_subsection", "uspc", "nber_subcat") -> endpoints

sapply(endpoints, FUN = function(x) {
  paste0('http://www.patentsview.org/api/', x, ".html") -> url
  readHTMLTable(doc = url) -> tab
  tab[[2]]
}, USE.NAMES = TRUE, simplify = FALSE) -> all_tabs

clean_field <- function(x) gsub("[^[:alnum:]_]", "", tolower(as.character(x)))

melt(all_tabs) %>%
  rename(field = `API Field Name`, data_type = Type, can_query = Query,
         endpoint = L1, group = Group) %>%
  select(endpoint, field, data_type, can_query, group) %>%
  mutate_each(funs(clean_field)) %>%
  mutate(endpoint = case_when(
    .$endpoint == "patent" ~ "patents",
    .$endpoint == "inventor" ~ "inventors",
    .$endpoint == "assignee" ~ "assignees",
    .$endpoint == "location" ~ "locations",
    .$endpoint == "cpc_subsection" ~ "cpc_subsections",
    .$endpoint == "uspc" ~ "uspc_mainclasses",
    .$endpoint == "nber_subcat" ~ "nber_subcategories"
  )) -> fields

# patent_id left off list for all endpoints:

data.frame(
  endpoint = unique(fields$endpoint),
  field = rep("patent_id", 7),
  data_type = rep("string", 7),
  can_query = rep("y", 7),
  group = rep("patents", 7),
  stringsAsFactors = FALSE
) %>%
  rbind(fields) %>%
  arrange(endpoint, field) %>%
  distinct() -> fieldsdf

write.csv(fieldsdf, "data-raw/fieldsdf.csv", row.names = FALSE)
# tools::checkRdaFiles("R/")
use_data(fieldsdf, internal = TRUE, overwrite = TRUE, compress = "gzip")