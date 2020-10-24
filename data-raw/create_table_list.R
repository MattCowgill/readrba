library(readrba)

# Scrape the RBA website ----
table_list <- scrape_table_list(cur_hist = "all")

# Indicate tables that can't be read ----
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

# Create a df of all individual series

all_data <- table_list %>%
  dplyr::filter(
    readable == TRUE
  ) %>%
  purrr::map2_dfr(
    .x = setNames(.$no, .$no),
    .y = .$current_or_historical,
    .f = ~ read_rba(table_no = .x, cur_hist = .y) %>% dplyr::mutate(cur_hist = .y),
    .id = "table_no"
  )

series_list <- all_data %>%
  dplyr::group_by(table_no, series, series_id, series_type,
                  table_title, cur_hist, description) %>%
  dplyr::summarise() %>%
  dplyr::ungroup()

usethis::use_data(table_list, series_list,
                  overwrite = TRUE, internal = TRUE)
