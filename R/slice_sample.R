#' Sample complete groups from a data frame
#' 
#' Samples complete groups from a grouped data frame, including
#' all of each group as part of the sample. Can be considered a form of
#' grouped bootstrap sampling.
#'
#' @param .data A grouped data frame, generated using `[dplyr::group_by](dplyr::group_by)`
#' @param n Number of samples to draw
#' @param replace Should sampling be done with replacement?
#' @param weight_by Optional expression to weight groups by (unquoted name)
#' @param ... Additional arguments passed to methods
#' 
#' @examples
#' ToothGrowth |>
#'    dplyr::group_by(supp, dose) |>
#'    slice_block(n = 2)
#'
#'
#' @return A data frame with sampled complete groups
#' @rdname slice_block
#' @export
slice_block <- function(.data, ...) {
  UseMethod("slice_block")
}

#' @rdname slice_block
#' @export
slice_block.data.frame <- function(.data, ...) {
  cli::cli_abort(c(
    "!" = "{.fun slice_block} requires a grouped data frame.",
    "i" = "Please group your data frame using {.fun dplyr::group_by} before using {.fun slice_block}."
  ))
}

#' @rdname slice_block
#' @export
slice_block.grouped_df <- function(
  .data,
  n = 1,
  replace = FALSE,
  weight_by = NULL,
  ...
) {

  gd <- dplyr::group_data(.data)
  n_groups <- nrow(gd)

  # Sample group indices
  if (n > n_groups && !replace) {
    cli::cli_abort(c(
      "!" = "{.arg n} ({n}) is greater than the number of groups ({n_groups}).",
      "i" = "Set {.arg replace = TRUE} to sample with replacement."
    ))
  }

  weight_by_quo <- rlang::enquo(weight_by)
  if (!rlang::quo_is_null(weight_by_quo)) {
    gd[[".weights"]] <- dplyr::summarise(.data, .weight = !!weight_by_quo)[[".weight"]]
  }
  
  block_indices <- sample(vctrs::vec_seq_along(gd), size = n, replace = replace, prob = gd[[".weights"]], ...)

  i <- vctrs::list_unchop(gd$.rows[block_indices])

  vctrs::vec_slice(.data, i)
}