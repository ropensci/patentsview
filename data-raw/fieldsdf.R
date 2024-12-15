library(tidyverse)
library(devtools)
library(rapiclient)

load_all()

# TODO(any): remove corrections when bugs are fixed

corrections <- read.table(
  text = "endpoint field data_type
  assignee assignee_type int
  patent assignees.assignee_type int
  patent/us_application_citation citation_document_number int
  publication assignees.assignee_type int
  publication rule_47_flag bool",
  header = TRUE,
  stringsAsFactors = FALSE
)

api <- get_api(url = "https://search.patentsview.org/static/openapi.json")

endpoint_paths <- names(api$paths)

# get rid of url parameter paths
endpoint_paths <- endpoint_paths[!grepl("\\{", endpoint_paths)]

# now we need to keep the parent portion of the nested patent/ and publication/ endpoints
endpoints <- sub("/api/v1/((patent/|publication/)?\\w+)/$", "\\1", endpoint_paths)

entities <-
  sapply(endpoint_paths, function(y) {
    success_response <- api$paths[y][1][[y]]$get$responses$`200`$content$`application/json`$schema$`$ref`
    gsub(".*/(\\w+SuccessResponse)", "\\1", success_response)
  })

lookup <- endpoints
names(lookup) <- entities

# detect "type":"string", "format":"date" (which is normal)
# Not sure if the other checks are standard but they're used in the patentsview object

data_type_intuit <- function(field_definition) {
  type <- field_definition$type
  format <- if ("format" %in% names(field_definition)) field_definition$format else ""
  example <- if ("example" %in% names(field_definition)) field_definition$example else ""
  as_is_types <- c("integer", "boolean", "array")

  if (type %in% as_is_types) {
    type
  } else if (type == "number") {
    "integer"
  } else if (format == "date") {
    "date"
  } else if (type == "string" && example == "double") {
    "number"
  } else {
    type
  }
}


# recurse if type is array?

extract_relevant_schema_info <- function(schema_elements) {
  lapply(schema_elements, function(schema_element) {
    middle <- lapply(
      names(api$components$schemas[[schema_element]]$properties[[1]]$items$properties),
      function(x, y) {
        data_type <- data_type_intuit(y[[x]])

        if (data_type == "array") {
          group <- x

          inner <- lapply(
            names(y[[x]]$items$properties),
            function(a, b) {
              # only nested one deep- wouldn't be an array here
              data.frame(
                endpoint = lookup[[schema_element]],
                field = paste0(group, ".", a),
                data_type = data_type_intuit(b[[a]]),
                group = group,
                common_name = a
              )
            },
            y[[x]]$items$properties
          )

          do.call(rbind, inner)
        } else {
          data.frame(
            endpoint = lookup[[schema_element]],
            field = x,
            data_type = data_type,
            group = names(api$components$schemas[[schema_element]]$properties),
            common_name = x
          )
        }
      }, api$components$schemas[[schema_element]]$properties[[1]]$items$properties
    )

    do.call(rbind, middle)
  }) %>%
    do.call(rbind, .) %>%
    arrange(endpoint, field) # sort so we can tell if the csv file changed
}

fieldsdf <- extract_relevant_schema_info(entities)

# TODO(any): remove hard coding corrections when possible

# We need to make two sets of corrections.  First we make hard coded type corrections
# that we reported as bugs
fieldsdf <- fieldsdf %>%
  left_join(corrections, by = c("endpoint", "field")) %>%
  mutate(data_type = coalesce(data_type.y, data_type.x)) %>%
  select(-data_type.x, -data_type.y) %>%
  relocate(data_type, .after = field)

# The second set of corrections is to append "_id" to fields and common_names below.
# The API team may not concider this to be a bug.  The OpenAPI object describes the
# API's return, not the requests we make (requests with the _id are returned without them)
# "patent","assignees.assignee","string","assignees","assignee"
# "patent","inventors.inventor","string","inventors","inventor"
# "publication","assignees.assignee","string","assignees","assignee"
# "publication","inventors.inventor","string","inventors","inventor"

add_id_to <- c("assignees.assignee", "inventors.inventor")

# change common_name first, condition isn't met if field is changed first DAMHIKT
fieldsdf <- fieldsdf %>%
  mutate(
    common_name = if_else(field %in% add_id_to, paste0(common_name, "_id"), common_name),
    field = if_else(field %in% add_id_to, paste0(field, "_id"), field)
  )

write.csv(fieldsdf, "data-raw/fieldsdf.csv", row.names = FALSE)

use_data(fieldsdf, internal = FALSE, overwrite = TRUE)
use_data(fieldsdf, internal = TRUE, overwrite = TRUE)
