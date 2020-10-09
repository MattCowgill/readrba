
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

Get data from the RBA in a tidy tibble.

**Note that this package is in an initial stage of development. Function
arguments are very likely to change.**

## Installation

``` r
remotes::install_github("mattcowgill/readrba")
```

## Example

``` r
rba_data <- readrba::read_rba(table_no = c("a1", "g1"))

dplyr::glimpse(rba_data)
#> Rows: 21,670
#> Columns: 11
#> $ date        <date> 1994-06-01, 1994-06-08, 1994-06-15, 1994-06-22, 1994-06-…
#> $ series      <chr> "Australian dollar investments", "Australian dollar inves…
#> $ value       <dbl> 13680, 13055, 13086, 12802, 13563, 12179, 14325, 12563, 1…
#> $ description <chr> "Australian dollar investments", "Australian dollar inves…
#> $ frequency   <chr> "Weekly", "Weekly", "Weekly", "Weekly", "Weekly", "Weekly…
#> $ type        <chr> "Original", "Original", "Original", "Original", "Original…
#> $ units       <chr> "$ million", "$ million", "$ million", "$ million", "$ mi…
#> $ source      <chr> "RBA", "RBA", "RBA", "RBA", "RBA", "RBA", "RBA", "RBA", "…
#> $ pub_date    <date> 2020-10-02, 2020-10-02, 2020-10-02, 2020-10-02, 2020-10-…
#> $ series_d    <chr> "ARBAAASTW", "ARBAAASTW", "ARBAAASTW", "ARBAAASTW", "ARBA…
#> $ table_title <chr> "A1 RESERVE BANK OF AUSTRALIA - LIABILITIES AND ASSETS - …

unique(rba_data$table_title)
#> [1] "A1 RESERVE BANK OF AUSTRALIA - LIABILITIES AND ASSETS - SUMMARY"
#> [2] "G1 CONSUMER PRICE INFLATION"
```
