
<!-- README.md is generated from README.Rmd. Please edit that file -->

# readrba <img src="man/figures/logo.png" align="right" height="139" />

<!-- badges: start -->

[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
[![R build
status](https://github.com/MattCowgill/readrba/workflows/R-CMD-check/badge.svg)](https://github.com/MattCowgill/readrba/actions)
[![Travis build
status](https://travis-ci.com/MattCowgill/readrba.svg?branch=master)](https://travis-ci.com/MattCowgill/readrba)
[![Codecov test
coverage](https://codecov.io/gh/MattCowgill/readrba/branch/master/graph/badge.svg)](https://codecov.io/gh/MattCowgill/readrba?branch=master)

<!-- badges: end -->

Get data from the [Reserve Bank of
Australia](https://rba.gov.au/statistics/tables/) in a
[tidy](https://cran.r-project.org/web/packages/tidyr/vignettes/tidy-data.html)
[tibble](https://tibble.tidyverse.org).

This package is still in active development. Some aspects of its
functionality are incomplete.

## Installation

The package is not yet on CRAN. Install from GitHub:

``` r
remotes::install_github("mattcowgill/readrba")
```

## Examples

### Reading RBA data

There is one main function in {readrba}: `read_rba()`.

Here’s how you fetch the current version of a single RBA statistical
table: table G1, consumer price inflation:

``` r
cpi_table <- readrba::read_rba(table_no = "g1")
```

The object returned by `read_rba()` is a tidy tibble (ie. in ‘long’
format):

``` r
dplyr::glimpse(cpi_table)
#> Rows: 3,843
#> Columns: 11
#> $ date        <date> 1922-06-01, 1922-09-01, 1922-12-01, 1923-03-01, 1923-06-…
#> $ series      <chr> "Consumer price index", "Consumer price index", "Consumer…
#> $ value       <dbl> 2.8, 2.8, 2.7, 2.7, 2.8, 2.9, 2.9, 2.8, 2.8, 2.8, 2.8, 2.…
#> $ frequency   <chr> "Quarterly", "Quarterly", "Quarterly", "Quarterly", "Quar…
#> $ series_type <chr> "Original", "Original", "Original", "Original", "Original…
#> $ units       <chr> "Index, 2011/12=100", "Index, 2011/12=100", "Index, 2011/…
#> $ source      <chr> "ABS / RBA", "ABS / RBA", "ABS / RBA", "ABS / RBA", "ABS …
#> $ pub_date    <date> 2020-07-30, 2020-07-30, 2020-07-30, 2020-07-30, 2020-07-…
#> $ series_id   <chr> "GCPIAG", "GCPIAG", "GCPIAG", "GCPIAG", "GCPIAG", "GCPIAG…
#> $ description <chr> "Consumer price index; All groups", "Consumer price index…
#> $ table_title <chr> "G1 Consumer Price Inflation", "G1 Consumer Price Inflati…
```

You can also request multiple tables. They’ll be returned together as
one tidy tibble:

``` r
rba_data <- readrba::read_rba(table_no = c("a1", "g1"))

dplyr::glimpse(rba_data)
#> Rows: 17,623
#> Columns: 11
#> $ date        <date> 1994-06-01, 1994-06-08, 1994-06-15, 1994-06-22, 1994-06-…
#> $ series      <chr> "Australian dollar investments", "Australian dollar inves…
#> $ value       <dbl> 13680, 13055, 13086, 12802, 13563, 12179, 14325, 12563, 1…
#> $ frequency   <chr> "Weekly", "Weekly", "Weekly", "Weekly", "Weekly", "Weekly…
#> $ series_type <chr> "Original", "Original", "Original", "Original", "Original…
#> $ units       <chr> "$ million", "$ million", "$ million", "$ million", "$ mi…
#> $ source      <chr> "RBA", "RBA", "RBA", "RBA", "RBA", "RBA", "RBA", "RBA", "…
#> $ pub_date    <date> 2020-10-23, 2020-10-23, 2020-10-23, 2020-10-23, 2020-10-…
#> $ series_id   <chr> "ARBAAASTW", "ARBAAASTW", "ARBAAASTW", "ARBAAASTW", "ARBA…
#> $ description <chr> "Australian dollar investments", "Australian dollar inves…
#> $ table_title <chr> "A1 Reserve Bank Of Australia - Liabilities And Assets - …

unique(rba_data$table_title)
#> [1] "A1 Reserve Bank Of Australia - Liabilities And Assets - Summary"
#> [2] "G1 Consumer Price Inflation"
```

You can also retrieve data based on the unique RBA time series
identifier(s). For example, to getch the consumer price index series
only:

``` r
cpi_series <- readrba::read_rba(series_id = "GCPIAG")
dplyr::glimpse(cpi_series)
#> Rows: 393
#> Columns: 11
#> $ date        <date> 1922-06-01, 1922-09-01, 1922-12-01, 1923-03-01, 1923-06-…
#> $ series      <chr> "Consumer price index", "Consumer price index", "Consumer…
#> $ value       <dbl> 2.8, 2.8, 2.7, 2.7, 2.8, 2.9, 2.9, 2.8, 2.8, 2.8, 2.8, 2.…
#> $ frequency   <chr> "Quarterly", "Quarterly", "Quarterly", "Quarterly", "Quar…
#> $ series_type <chr> "Original", "Original", "Original", "Original", "Original…
#> $ units       <chr> "Index, 2011/12=100", "Index, 2011/12=100", "Index, 2011/…
#> $ source      <chr> "ABS / RBA", "ABS / RBA", "ABS / RBA", "ABS / RBA", "ABS …
#> $ pub_date    <date> 2020-07-30, 2020-07-30, 2020-07-30, 2020-07-30, 2020-07-…
#> $ series_id   <chr> "GCPIAG", "GCPIAG", "GCPIAG", "GCPIAG", "GCPIAG", "GCPIAG…
#> $ description <chr> "Consumer price index; All groups", "Consumer price index…
#> $ table_title <chr> "G1 Consumer Price Inflation", "G1 Consumer Price Inflati…
unique(cpi_series$series_id)
#> [1] "GCPIAG"
```

The convenience function `read_rba_seriesid()` is a wrapper around
`read_rba()`. This means `read_rba_seriesid("GCPIAG")` is equivalent to
`read_rba(series_id = "GCPIAG")`.

By default, `read_rba()` fetches the current version of whatever table
you request. You can specify the historical version of a table, if it’s
available, using the `cur_hist` argument:

``` r

hist_a11 <- readrba::read_rba(table_no = "a1.1", cur_hist = "historical")

dplyr::glimpse(hist_a11)
#> Rows: 8,889
#> Columns: 11
#> $ date        <date> 1977-07-31, 1977-08-31, 1977-09-30, 1977-10-31, 1977-11-…
#> $ series      <chr> "Australian Government Deposits", "Australian Government …
#> $ value       <dbl> 654, 665, 695, 609, 560, 614, 596, 505, 688, 642, 587, 64…
#> $ frequency   <chr> "Monthly", "Monthly", "Monthly", "Monthly", "Monthly", "M…
#> $ series_type <chr> "Original; average of weekly data for the month", "Origin…
#> $ units       <chr> "$ million", "$ million", "$ million", "$ million", "$ mi…
#> $ source      <chr> "RBA", "RBA", "RBA", "RBA", "RBA", "RBA", "RBA", "RBA", "…
#> $ pub_date    <date> 2015-06-26, 2015-06-26, 2015-06-26, 2015-06-26, 2015-06-…
#> $ series_id   <chr> "ARBALDOGIAG", "ARBALDOGIAG", "ARBALDOGIAG", "ARBALDOGIAG…
#> $ description <chr> "Australian Government Deposits", "Australian Government …
#> $ table_title <chr> "A1.1 Reserve Bank Of Australia - Liabilities And Assets"…
```

### Browsing RBA data

Two functions are provided to help you find the table number or series
ID you need. These are `browse_rba_tables()` and `browse_rba_series()`.
Each returns a tibble with information about the available RBA data:

``` r
readrba::browse_rba_tables()
#> # A tibble: 123 x 5
#>    title                   no    url                  current_or_histo… readable
#>    <chr>                   <chr> <chr>                <chr>             <lgl>   
#>  1 Liabilities and Assets… A1    https://rba.gov.au/… current           TRUE    
#>  2 Liabilities and Assets… A1.1  https://rba.gov.au/… current           TRUE    
#>  3 Monetary Policy Changes A2    https://rba.gov.au/… current           TRUE    
#>  4 Monetary Policy Operat… A3    https://rba.gov.au/… current           TRUE    
#>  5 Holdings of Australian… A3.1  https://rba.gov.au/… current           TRUE    
#>  6 Foreign Exchange Trans… A4    https://rba.gov.au/… current           TRUE    
#>  7 Daily Foreign Exchange… A5    https://rba.gov.au/… current           FALSE   
#>  8 Banknotes on Issue by … A6    https://rba.gov.au/… current           TRUE    
#>  9 Detected Australian Co… A7    https://rba.gov.au/… current           TRUE    
#> 10 Assets of Financial In… B1    https://rba.gov.au/… current           TRUE    
#> # … with 113 more rows
```

## Data availability

The `read_rba()` function is able to import most tables on the
[Statistical Tables](https://rba.gov.au/statistics/tables/) page of the
RBA website. These are the tables that are downloaded when you use
`read_rba(cur_hist = "current")`, the default.

`read_rba()` can also download many of the tables on the [Historical
Data](https://rba.gov.au/statistics/historical-data.html) page of the
RBA website. To get these, specify `cur_hist = "historical"` in
`read_rba()`.

### Historical exchange rate tables

The historical exchange rate tables do not have table numbers on the RBA
website. They can still be downloaded, using the following table
numbers:

| Table title                                                                      | table\_no          |
| :------------------------------------------------------------------------------- | :----------------- |
| Exchange Rates – Daily – 1983 to 1986                                            | ex\_daily\_8386    |
| Exchange Rates – Daily – 1987 to 1990                                            | ex\_daily\_8790    |
| Exchange Rates – Daily – 1991 to 1994                                            | ex\_daily\_9194    |
| Exchange Rates – Daily – 1995 to 1998                                            | ex\_daily\_9598    |
| Exchange Rates – Daily – 1999 to 2002                                            | ex\_daily\_9902    |
| Exchange Rates – Daily – 2003 to 2006                                            | ex\_daily\_0306    |
| Exchange Rates – Daily – 2007 to 2009                                            | ex\_daily\_0709    |
| Exchange Rates – Daily – 2010 to 2013                                            | ex\_daily\_1013    |
| Exchange Rates – Daily – 2014 to 2017                                            | ex\_daily\_1417    |
| Exchange Rates – Daily – 2018 to Current                                         | ex\_daily\_18cur   |
| Exchange Rates – Monthly – January 2010 to latest complete month of current year | ex\_monthly\_10cur |
| Exchange Rates – Monthly – July 1969 to December 2009                            | ex\_monthly\_6909  |

### Non-standard tables

`read_rba()` is currently only able to import RBA statistical tables
that are formatted in a (more or less) standard way. Some are formatted
in a non-standard way, either because they’re distributions rather than
time series, or because they’re particularly old.

Tables that are **not** able to be downloaded are:

| Table title                                                               | table\_no |
| :------------------------------------------------------------------------ | :-------- |
| Daily Foreign Exchange Market Intervention Transactions                   | A5        |
| Household Balance Sheets – Distribution                                   | E3        |
| Household Gearing – Distribution                                          | E4        |
| Household Financial Assets – Distribution                                 | E5        |
| Household Non-Financial Assets – Distribution                             | E6        |
| Household Debt – Distribution                                             | E7        |
| Open Market Operations – 2012 to 2013                                     | A3        |
| Open Market Operations – 2009 to 2011                                     | A3        |
| Open Market Operations – 2003 to 2008                                     | A3        |
| Individual Banks’ Assets – 1991–1992 to 1997–1998                         | J1        |
| Individual Banks’ Liabilities – 1991–1992 to 1997–1998                    | J2        |
| Treasury Note Tenders - 1989–2006                                         | E4        |
| Treasury Bond Tenders – 1982–2006                                         | E5        |
| Treasury Bond Tenders – Amount Allotted, by Years to Maturity – 1982–2006 | E5        |
| Treasury Bond Switch Tenders – 2008                                       | E6        |
| Treasury Capital Indexed Bonds – 1985–2006                                | E7        |
| Capital Market Yields – Government Bonds – Daily – 1995 to 17 May 2013    | F2        |
| Capital Market Yields – Government Bonds – Monthly – 1969 to May 2013     | F2        |
| Indicative Mid Rates of Australian Government Securities – 1992 to 2008   | F16       |
| Indicative Mid Rates of Australian Government Securities – 2009 to 2018   | F16       |
| Zero-coupon Interest Rates – Analytical Series – 1992 to 2008             | F17       |

## Issues and contributions

I welcome any feature requests or bug reports. The best way is to file a
[GitHub issue](https://github.com/MattCowgill/readrba/issues).

I would welcome contributions to the package. Please start by filing an
issue, outlining the bug you intend to fix or functionality you intend
to add or modify.

## Disclaimer

This package is not affiliated with or endorsed by the Reserve Bank of
Australia. All data is provided subject to any conditions and
restrictions set out on the RBA website.
