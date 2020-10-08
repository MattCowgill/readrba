library(readrba)

table_list <- scrape_table_list() %>%
  dplyr::mutate(current_or_historical = "current")

usethis::use_data(table_list, overwrite = TRUE, internal = TRUE)
