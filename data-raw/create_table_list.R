library(readrba)

table_list <- scrape_table_list()

usethis::use_data(table_list, overwrite = TRUE, internal = TRUE)
