# egworkflow

``` r
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
#library(blockstrap)
```

## Introduction to Blockstrap

Blockstrap is an R package developed for resampling data structures that
naturally come in blocks. A common example is the line-listed hospital
admission data, where each subject may appear in multiple rows. These
rows can be grouped into meaningful units such as a sequence of visits
by the same subject that occur close together. We refer to each such
grouping as a block.

Blockstrap provides tools to perform a block bootstrap, resampling these
blocks rather than resampling individual rows independently as in a
traditional bootstrap.

In this document, we demonstrate how to:

- Create an example line-listed dataset in the hospital admission
  context
- Partition the dataset into blocks
- Perform block bootstrap using slice_block() function

### Generate an example dataset

For illustration, we use the create_fake_subjectDB() function from the
HospitalNetwork package to generate a fake subject database containing
admission/discharge records.

``` r
library(HospitalNetwork)
#> Loading required package: data.table
#> 
#> Attaching package: 'data.table'
#> The following objects are masked from 'package:dplyr':
#> 
#>     between, first, last
set.seed(1)
df<- create_fake_subjectDB()
df
#>         sID    fID      Adate      Ddate
#>      <char> <char>     <POSc>     <POSc>
#>   1:   s001    f07 2019-01-23 2019-02-02
#>   2:   s001    f01 2019-03-07 2019-03-10
#>   3:   s002    f05 2019-02-24 2019-03-03
#>   4:   s002    f10 2019-03-25 2019-03-27
#>   5:   s002    f06 2019-04-23 2019-04-27
#>  ---                                    
#> 227:   s098    f01 2019-02-25 2019-03-03
#> 228:   s099    f04 2019-01-27 2019-01-31
#> 229:   s100    f10 2019-02-04 2019-02-08
#> 230:   s100    f01 2019-03-19 2019-03-23
#> 231:   s100    f08 2019-05-04 2019-05-10
```

Here, df contains four columns:

- `sID`: Subject ID
- `fID`: Facility ID
- `Adate`: Admission date for the visit
- `Ddate`: Discharge date for the visit

### Group rows into blocks

We define a block as a sequence of visits by the same subject that occur
close together, that is, a new block begins when:

- It is the first record for the subject, or
- The difference in days between the previous discharge (`Ddate`) and
  the current admission (`Adate`) exceeds 40 days

``` r
df2<- df |>  
  group_by(sID) |>
  mutate( Adate = as.Date(Adate),
          Ddate = as.Date(Ddate)) |>
  arrange(Adate, .by_group= TRUE) |>
  mutate( diff_time = Adate - lag(Ddate),
          is_start = is.na(diff_time) | diff_time > 40,
          idx_within_sid = cumsum(is_start),
          idx_block = as.factor(paste0(sID, "_", idx_within_sid)))

df2
#> # A tibble: 231 × 8
#> # Groups:   sID [100]
#>    sID   fID   Adate      Ddate      diff_time is_start idx_within_sid idx_block
#>    <chr> <chr> <date>     <date>     <drtn>    <lgl>             <int> <fct>    
#>  1 s001  f07   2019-01-23 2019-02-02 NA days   TRUE                  1 s001_1   
#>  2 s001  f01   2019-03-07 2019-03-10 33 days   FALSE                 1 s001_1   
#>  3 s002  f05   2019-02-24 2019-03-03 NA days   TRUE                  1 s002_1   
#>  4 s002  f10   2019-03-25 2019-03-27 22 days   FALSE                 1 s002_1   
#>  5 s002  f06   2019-04-23 2019-04-27 27 days   FALSE                 1 s002_1   
#>  6 s003  f09   2019-02-08 2019-02-15 NA days   TRUE                  1 s003_1   
#>  7 s003  f01   2019-03-26 2019-04-02 39 days   FALSE                 1 s003_1   
#>  8 s004  f10   2019-01-30 2019-02-04 NA days   TRUE                  1 s004_1   
#>  9 s004  f09   2019-02-19 2019-02-23 15 days   FALSE                 1 s004_1   
#> 10 s004  f07   2019-03-29 2019-04-07 34 days   FALSE                 1 s004_1   
#> # ℹ 221 more rows
```

The column `idx_block` is a factor that identifies which block each row
belongs to. Note that rows that share the identical entries in
`idx_block` belong to the same block.

### Block bootstrap

With the block IDs defined, we use the slice_block() function to perform
block bootstrap.

In this example,
