library(readrba)

# Scrape the RBA website ----
table_list <- scrape_table_list(cur_hist = "all")

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
  dplyr::group_by(
    table_no, series, series_id, series_type,
    table_title, cur_hist, description
  ) %>%
  dplyr::summarise() %>%
  dplyr::ungroup()

usethis::use_data(table_list, series_list,
  overwrite = TRUE, internal = TRUE
)
