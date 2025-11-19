# Sample complete groups from a data frame

Samples complete groups from a grouped data frame, including all of each
group as part of the sample. Can be considered a form of grouped
bootstrap sampling.

## Usage

``` r
slice_block(.data, ...)

# S3 method for class 'data.frame'
slice_block(.data, ...)

# S3 method for class 'grouped_df'
slice_block(.data, n = 1, replace = FALSE, weight_by = NULL, ...)
```

## Arguments

- .data:

  A grouped data frame, generated using
  `[dplyr::group_by](dplyr::group_by)`

- ...:

  Additional arguments passed to methods

- n:

  Number of samples to draw

- replace:

  Should sampling be done with replacement?

- weight_by:

  Optional expression to weight groups by (unquoted name)

## Value

A data frame with sampled complete groups

## Examples

``` r
ToothGrowth |>
   dplyr::group_by(supp, dose) |>
   slice_block(n = 2)
#> # A tibble: 20 × 3
#> # Groups:   supp, dose [2]
#>      len supp   dose
#>    <dbl> <fct> <dbl>
#>  1   4.2 VC      0.5
#>  2  11.5 VC      0.5
#>  3   7.3 VC      0.5
#>  4   5.8 VC      0.5
#>  5   6.4 VC      0.5
#>  6  10   VC      0.5
#>  7  11.2 VC      0.5
#>  8  11.2 VC      0.5
#>  9   5.2 VC      0.5
#> 10   7   VC      0.5
#> 11  16.5 VC      1  
#> 12  16.5 VC      1  
#> 13  15.2 VC      1  
#> 14  17.3 VC      1  
#> 15  22.5 VC      1  
#> 16  17.3 VC      1  
#> 17  13.6 VC      1  
#> 18  14.5 VC      1  
#> 19  18.8 VC      1  
#> 20  15.5 VC      1  

```
