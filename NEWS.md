# readrba dev version
* Fixes for issues in RBA tables (eg. nearly-but-not-entirely empty columns in spreadsheets)

# readrba 0.1.9
* Bug fixes
* Fix for omitted data in May SMP forecast table

# readrba 0.1.8
* read_forecasts() / rba_forecasts() updated to work with the new SMP format

# readrba 0.1.7
* Internal metadata refreshed, reflecting changes to the tables on the RBA website. Thanks

# readrba 0.1.6
* The read_forecasts() function now returns some forecasts from the 2018-22 period
that were previously erroneously omitted

# readrba 0.1.5
* Historical tables F16 and F17 cannot be loaded by read_rba() - this has now 
been made explicit. The ability to import these tables *may* be added in future.
* The RBA has made various changes to its statistical tables; some changes
have been made to the package to reflect these changes. 

# readrba 0.1.4
* rba_forecasts() now checks to ensure there's only one distinct forecast_date-date-series combination, as duplicates can arise when forecasts from multiple sources are combined
* Minor fixes to account for deprecations in dependencies

# readrba 0.1.3
* Additional checks to ensure file format (eg. "xls") matches file content (eg. "xlsx")
* More examples added to vignette

# readrba 0.1.2
* refreshed internal data, update vignette and README
* Forecasts in the 2014-2018 period now more complete, thanks to Angus Moore

# readrba 0.1.1
* utils::download.file() used to attempt to address corporate network problems with curl
* 'www' added to URLs, to fix error encountered on some systems

# readrba 0.1.0
* Speed and stability improvements
* More non-standard tables can be tidied

# readrba 0.0.4
* `read_cashrate()` convenience function added
* Speed improvements, particularly when using series IDs

# readrba 0.0.3
* Historical and current RBA forecasts now available via `rba_forecasts()`
* Bug fixes and speed improvements

# readrba 0.0.2
* Can now use `series_id` argument to `read_rba()` to fetch based on series ID(s)
* Examine available RBA data using `browse_rba_series()` and `browse_rba_tables()`
* `cur_hist = "all"` no longer allowed
* Some non-standard tables now able to be tidied
* Added a `NEWS.md` file to track changes to the package.
