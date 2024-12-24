# Vector of queries (one for each endpoint) that are used during testing. We
# need this b/c in the new version of the api, only ten of the endpoints are
# searchable by patent number (i.e., we can't use a generic patent number
# search query).  further, now patent_number has been patent_id

TEST_QUERIES <- c(
  "assignee" = '{"_text_phrase":{"assignee_individual_name_last": "Clinton"}}',
  "cpc_class" = '{"cpc_class_id": "A01"}',
  "cpc_group" = '{"cpc_group_id": "A01B1/00"}',
  "cpc_subclass" = '{"cpc_subclass_id": "A01B"}',
  "g_brf_sum_text" = '{"patent_id": "11540434"}',
  "g_claim" = '{"patent_id": "11540434"}',
  "g_detail_desc_text" = '{"patent_id": "11540434"}',
  "g_draw_desc_text" = '{"patent_id": "11540434"}',
  "inventor" = '{"_text_phrase":{"inventor_name_last":"Clinton"}}',
  "ipc" = '{"ipc_id": "1"}',
  "location" = '{"location_name":"Chicago"}',
  "patent" = '{"patent_id":"5116621"}',
  "patent/attorney" = '{"attorney_id":"005dd718f3b829bab9e7e7714b3804a5"}',
  "patent/foreign_citation" = '{"patent_id": "10000001"}',
  "patent/other_reference" = '{"patent_id": "3930306"}',
  "patent/rel_app_text" = '{"patent_id": "10000007"}',
  "patent/us_application_citation" = '{"patent_id": "10966293"}',
  "patent/us_patent_citation" = '{"patent_id":"5116621"}',
  "pg_brf_sum_text" = '{"document_number": 20240324479}',
  "pg_claim" = '{"document_number": 20230000001}',
  "pg_detail_desc_text" = '{"document_number": 20230000001}',
  "pg_draw_desc_text" = '{"document_number": 20230000001}',
  "publication" = '{"document_number": 20010000002}',
  "publication/rel_app_text" = '{"document_number": 20010000001}',
  "uspc_mainclass" = '{"uspc_mainclass_id":"30"}',
  "uspc_subclass" = '{"uspc_subclass_id": "100/1"}',
  "wipo" = '{"wipo_id": "1"}'
)

to_plural <- function(x) {
   pk <- get_ok_pk(x)
   fieldsdf[fieldsdf$endpoint == x & fieldsdf$field == pk, "group"]
}

to_singular <- function(entity) {
    endpoint_df <- fieldsdf[fieldsdf$group == entity, ]
    endpoint <- unique(endpoint_df$endpoint)

    # watch out here- several endpoints return entities that are groups returned
    # by the patent and publication endpoints (attorneys, inventors, assignees)
    if(length(endpoint) > 1) {
      endpoint <- endpoint[!endpoint %in% c("patent", "publication")]
    }

    # can't distinguish rel_app_texts between patent/rel_app_text and publication/rel_app_text
    endpoint
}
