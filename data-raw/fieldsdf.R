library(tidyverse)
library(devtools)
library(rapiclient)

load_all()

# Temp swagger API spec
# TODO(any): Update with actual PatentsView version after its issues are sorted
api <- get_api(url = "https://patentsview.historicip.com/swagger/openapi.json")

endpoint_paths <- names(api$paths)
endpoint_paths <- endpoint_paths[!grepl("\\{", endpoint_paths)]
endpoints <- gsub(".*/(\\w+)(/$)?", "\\1", endpoint_paths)
entities <-
  sapply(endpoint_paths, function(y) {
    success_response <- api$paths[y][1][[y]]$get$responses$`200`$content$`application/json`$schema$`$ref`
    gsub(".*/(\\w+)SuccessResponse", "\\1", success_response)
  })

try_get_ref <- function(list) {
  if ("items" %in% names(list)) {
    gsub(".*/", "", list[["items"]][["$ref"]])
  } else {
    NA
  }
}

extract_relevant_schema_info <- function(schema_elements) {
  out_list <- lapply(schema_elements, function(schema_element) {
    lapply(
      api$components$schemas[[schema_element]]$properties,
      function(x) data.frame(
        type = x$type,
        ref = try_get_ref(x)
      )
    ) %>%
      do.call(rbind, .) %>%
      rownames_to_column() %>%
      setNames(c("field", "data_type", "ref")) %>%
      mutate(schema_element = schema_element)
  })
  do.call(rbind, out_list)
}

nonnested_elements <- extract_relevant_schema_info(entities)

schema_element_names <- names(api$components$schemas)
nested_elements <- schema_element_names[grepl("Nested$", schema_element_names)]
nested_elements <- c("YearlyPatents", nested_elements)
nested_elements <- extract_relevant_schema_info(nested_elements)

lookup <- sapply(endpoints, to_plural)
names(lookup) <- entities

fieldsdf <-
  nonnested_elements %>%
    left_join(nested_elements, by = c("ref" = "schema_element")) %>%
    mutate(
      common_name = ifelse(is.na(ref), field.x, field.y),
      data_type = ifelse(is.na(ref), data_type.x, data_type.y),
      group = ifelse(is.na(ref), lookup[schema_element], field.x),
      endpoint = lookup[schema_element],
      field = ifelse(is.na(ref), common_name, paste0(group, ".", common_name))
    ) %>%
    mutate(data_type = ifelse(grepl("_date$", common_name), "date", data_type)) %>%
    select(endpoint, field, data_type, group, common_name)

write.csv(fieldsdf, "data-raw/fieldsdf.csv", row.names = FALSE)

use_data(fieldsdf, internal = FALSE, overwrite = TRUE)
use_data(fieldsdf, internal = TRUE, overwrite = TRUE)
