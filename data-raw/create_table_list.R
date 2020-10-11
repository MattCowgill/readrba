library(readrba)

# Scrape the RBA website ----
table_list <- scrape_table_list(cur_hist = "all")

# Indicate tables that can't be read----
# Temporary; replace this with a function, then work on loading these
# non-TS spreadsheets

table_list <- table_list %>%
  dplyr::mutate(
    readable =
      dplyr::case_when(
        current_or_historical == "current" &
          no %in% c("A5", "E3", "E4", "E5", "E6", "E7") ~ FALSE,
        current_or_historical == "historical" &
          no %in% c(
            "A3", "J1", "J2", "E4", "E5", "E6", "E7",
            "F2", "F16", "F17"
          ) ~ FALSE,
        TRUE ~ TRUE
      )
  )

usethis::use_data(table_list, overwrite = TRUE, internal = TRUE)
