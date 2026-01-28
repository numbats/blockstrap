# Example Workflow

``` r
library(dplyr)
library(blockstrap)
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

For illustration, we use the
[`create_fake_subjectDB()`](https://pascalcrepey.github.io/HospitalNetwork/reference/create_fake_subjectDB.html)
function from the `HospitalNetwork` package to generate a fake subject
database containing admission/discharge records. Note that this dataset
includes $100$ subjects and each subject can have more than one record.

``` r
library(HospitalNetwork)
set.seed(1)
subject_db <- create_fake_subjectDB()

head(subject_db)
#>       sID    fID      Adate      Ddate
#>    <char> <char>     <POSc>     <POSc>
#> 1:   s001    f07 2019-01-23 2019-02-02
#> 2:   s001    f01 2019-03-07 2019-03-10
#> 3:   s002    f05 2019-02-24 2019-03-03
#> 4:   s002    f10 2019-03-25 2019-03-27
#> 5:   s002    f06 2019-04-23 2019-04-27
#> 6:   s003    f09 2019-02-08 2019-02-15
```

Here, `subject_db` contains four columns:

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
grouped_subjects <- subject_db |>  
  group_by(sID) |>
  mutate(Adate = as.Date(Adate),
         Ddate = as.Date(Ddate)) |>
  arrange(Adate, .by_group= TRUE) |>
  mutate(diff_time = Adate - lag(Ddate),
         is_start = is.na(diff_time) | diff_time > 40,
         idx_within_sid = cumsum(is_start),
         idx_block = as.factor(paste0(sID, "_",   idx_within_sid)))

head(grouped_subjects)
#> # A tibble: 6 × 8
#> # Groups:   sID [3]
#>   sID   fID   Adate      Ddate      diff_time is_start idx_within_sid idx_block
#>   <chr> <chr> <date>     <date>     <drtn>    <lgl>             <int> <fct>    
#> 1 s001  f07   2019-01-23 2019-02-02 NA days   TRUE                  1 s001_1   
#> 2 s001  f01   2019-03-07 2019-03-10 33 days   FALSE                 1 s001_1   
#> 3 s002  f05   2019-02-24 2019-03-03 NA days   TRUE                  1 s002_1   
#> 4 s002  f10   2019-03-25 2019-03-27 22 days   FALSE                 1 s002_1   
#> 5 s002  f06   2019-04-23 2019-04-27 27 days   FALSE                 1 s002_1   
#> 6 s003  f09   2019-02-08 2019-02-15 NA days   TRUE                  1 s003_1
```

The column `idx_block` is a factor that identifies which block each row
belongs to. Note that rows that share the identical entries in
`idx_block` belong to the same block.

``` r
nrow(distinct(grouped_subjects,idx_block))
#> [1] 125
```

There are $125$ unique blocks in the dataset.

### Block bootstrap

With the block IDs defined, we use the
[`slice_block()`](http://www.michaellydeamore.com/blockstrap/reference/slice_block.md)
function to perform block bootstrap. Here, we sample 10 blocks with
replacement:

``` r
blockstrapped_db <- grouped_subjects |>
  group_by(idx_block) |>
  slice_block(n = 10, replace=TRUE)

head(blockstrapped_db)
#> # A tibble: 6 × 8
#> # Groups:   idx_block [3]
#>   sID   fID   Adate      Ddate      diff_time is_start idx_within_sid idx_block
#>   <chr> <chr> <date>     <date>     <drtn>    <lgl>             <int> <fct>    
#> 1 s037  f08   2019-01-29 2019-02-03 NA days   TRUE                  1 s037_1   
#> 2 s037  f01   2019-03-10 2019-03-13 35 days   FALSE                 1 s037_1   
#> 3 s039  f08   2019-02-03 2019-02-11 NA days   TRUE                  1 s039_1   
#> 4 s039  f02   2019-03-14 2019-03-18 31 days   FALSE                 1 s039_1   
#> 5 s039  f10   2019-04-10 2019-04-15 23 days   FALSE                 1 s039_1   
#> 6 s055  f10   2019-01-16 2019-01-21 NA days   TRUE                  1 s055_1
```

`blockstrapped_db` is the resulting dataset sampled using block
bootstrap and can be used for further statistical analysis. The example
above demonstrates sampling with equal weights, but the
[`slice_block()`](http://www.michaellydeamore.com/blockstrap/reference/slice_block.md)
function also allows for weighted sampling. For instance, we use the
block size to give larger blocks a higher probability of being selected
to generate `blockstrapped_db`.

``` r
blockstrapped_db <- grouped_subjects |>
  group_by(idx_block) |>
  slice_block(n = 10, replace=TRUE, weight_by = n())

blockstrapped_db
#> # A tibble: 21 × 8
#> # Groups:   idx_block [9]
#>    sID   fID   Adate      Ddate      diff_time is_start idx_within_sid idx_block
#>    <chr> <chr> <date>     <date>     <drtn>    <lgl>             <int> <fct>    
#>  1 s051  f04   2019-02-16 2019-02-17 NA days   TRUE                  1 s051_1   
#>  2 s051  f05   2019-03-16 2019-03-26 27 days   FALSE                 1 s051_1   
#>  3 s051  f07   2019-04-26 2019-05-05 31 days   FALSE                 1 s051_1   
#>  4 s051  f04   2019-06-10 2019-06-15 36 days   FALSE                 1 s051_1   
#>  5 s070  f08   2019-01-21 2019-01-26 NA days   TRUE                  1 s070_1   
#>  6 s070  f05   2019-01-27 2019-01-31  1 days   FALSE                 1 s070_1   
#>  7 s070  f07   2019-03-02 2019-03-03 30 days   FALSE                 1 s070_1   
#>  8 s070  f03   2019-03-30 2019-04-03 27 days   FALSE                 1 s070_1   
#>  9 s077  f10   2019-02-10 2019-02-17 NA days   TRUE                  1 s077_1   
#> 10 s095  f04   2019-01-24 2019-02-03 NA days   TRUE                  1 s095_1   
#> # ℹ 11 more rows
```
