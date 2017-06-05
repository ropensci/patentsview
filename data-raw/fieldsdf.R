library(XML)
library(reshape2)
library(dplyr)
library(devtools)

endpoints <- c("patent", "inventor", "assignee", "location", "cpc_subsection",
               "uspc", "nber_subcat")

all_tabs <- sapply(endpoints, FUN = function(x) {
  url <- paste0("http://www.patentsview.org/api/", x, ".html")
  tab <- readHTMLTable(doc = url)
  tab[[2]]
}, USE.NAMES = TRUE, simplify = FALSE)

clean_field <- function(x) gsub("[^[:alnum:]_]", "", tolower(as.character(x)))

fields <-
  melt(all_tabs) %>%
    rename(field = `API Field Name`, data_type = Type, can_query = Query,
           endpoint = L1, group = Group, common_name = `Common Name`,
           description = Description) %>%
    select(endpoint, field, data_type, can_query, group,
           common_name, description) %>%
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

# patent_id left off list for all endpoints:

fieldsdf <-
  data.frame(
    endpoint = unique(fields$endpoint),
    field = rep("patent_id", 7),
    data_type = rep("string", 7),
    can_query = rep("y", 7),
    group = rep("patents", 7),
    common_name = rep("Patent ID", 7),
    description = rep("Unique database ID for patent", 7),
    stringsAsFactors = FALSE
  ) %>%
    rbind(fields) %>%
    arrange(endpoint, field) %>%
    distinct()

write.csv(fieldsdf, "data-raw/fieldsdf.csv", row.names = FALSE)
use_data(fieldsdf, internal = FALSE, overwrite = TRUE)