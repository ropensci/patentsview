# Vector of queries (one for each endpoint) that are used during testing. We
# need this b/c in the new version of the api, only three of the endpoints are
# searchable by patent number (i.e., we can't use a generic patent number
# search query).

TEST_QUERIES <- c(
  "application_citations" = '{"patent_number": "10966293"}',
  "assignees" = '{"_text_phrase":{"name_last": "Clinton"}}',
  "cpc_groups" = '{"cpc_group_id": "A01B"}',
  "cpc_subgroups" = '{"cpc_subgroup_id": "A01B1/00"}',
  "cpc_subsections" = '{"cpc_subsection_id": "A01"}',
  "inventors" = '{"_text_phrase":{"name_last":"Clinton"}}',
  "nber_categories" = '{"nber_category_id": "1"}',
  "nber_subcategories" = '{"nber_subcategory_id": "11"}',
  "patents" = '{"patent_number":"5116621"}',
  "patent_citations" = '{"patent_number":"5116621"}',
  "uspc_mainclasses" = '{"uspc_mainclass_id":"30"}',
  "uspc_subclasses" = '{"uspc_subclass_id": "100/1"}'
)
