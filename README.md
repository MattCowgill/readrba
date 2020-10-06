
<!-- README.md is generated from README.Rmd. Please edit that file -->

# readrba

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R build
status](https://github.com/MattCowgill/readrba/workflows/R-CMD-check/badge.svg)](https://github.com/MattCowgill/readrba/actions)
[![Travis build
status](https://travis-ci.com/MattCowgill/readrba.svg?branch=master)](https://travis-ci.com/MattCowgill/readrba)
[![Codecov test
coverage](https://codecov.io/gh/MattCowgill/readrba/branch/master/graph/badge.svg)](https://codecov.io/gh/MattCowgill/readrba?branch=master)

<!-- badges: end -->

Get data from the RBA in a tidy tibble. Note that this package is in an
initial stage of development. Function arguments are very likely to
change.

## Installation

``` r
remotes::install_github("mattcowgill/readrba")
```

## Example

``` r
rba_data <- readrba::read_rba(table_filenames = c("g01hist", "g03hist"))

dplyr::glimpse(rba_data)
#> Rows: 8,921
#> Columns: 11
#> $ date        <date> 1922-06-01, 1922-09-01, 1922-12-01, 1923-03-01, 1923-06-…
#> $ series      <chr> "Consumer price index", "Consumer price index", "Consumer…
#> $ value       <dbl> 2.8, 2.8, 2.7, 2.7, 2.8, 2.9, 2.9, 2.8, 2.8, 2.8, 2.8, 2.…
#> $ description <chr> "Consumer price index; All groups", "Consumer price index…
#> $ frequency   <chr> "Quarterly", "Quarterly", "Quarterly", "Quarterly", "Quar…
#> $ type        <chr> "Original", "Original", "Original", "Original", "Original…
#> $ units       <chr> "Index, 2011/12=100", "Index, 2011/12=100", "Index, 2011/…
#> $ source      <chr> "ABS / RBA", "ABS / RBA", "ABS / RBA", "ABS / RBA", "ABS …
#> $ pub_date    <date> 2020-07-30, 2020-07-30, 2020-07-30, 2020-07-30, 2020-07-…
#> $ series_d    <chr> "GCPIAG", "GCPIAG", "GCPIAG", "GCPIAG", "GCPIAG", "GCPIAG…
#> $ table_title <chr> "G1 CONSUMER PRICE INFLATION", "G1 CONSUMER PRICE INFLATI…

unique(rba_data$table_title)
#> [1] "G1 CONSUMER PRICE INFLATION" "G3 INFLATION EXPECTATIONS"
```
