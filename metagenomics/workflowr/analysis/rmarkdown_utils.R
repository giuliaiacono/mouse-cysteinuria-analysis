library(tidyverse)

show_kable <- function(df) {
  df %>% kableExtra::kbl(booktabs = TRUE) %>%
         kableExtra::kable_styling(bootstrap_options = c("striped", "condensed"), font_size = 10) %>%
         kableExtra::column_spec(2, width = "6em") %>%
         kableExtra::scroll_box(width = "100%", height = "200px")
}

show_table <- function(df, pageLength = 20, digits = 3, ...) {
  dt <- DT::datatable(df, options = list(pageLength = pageLength), ...)
  if (!is.null(digits)) {
    numeric_cols <- names(df)[sapply(df, is.numeric)]
    return(dt %>% DT::formatRound(columns = numeric_cols, digits = digits))
  }
  return(dt)
}

show_table_extra <- function(df, pageLength = 20, digits = 3, ...) {
  dt <- DT::datatable(
    df,
    extensions = 'Buttons', 
    rownames = FALSE,
    options = list(
      scrollX = TRUE,
      lengthMenu = c(5, 10, 20, 100),
      pageLength = pageLength,
      paging = TRUE,
      searching = TRUE,
      fixedColumns = TRUE,
      autoWidth = TRUE,
      ordering = TRUE,
      dom = 'Blfrtip',
      buttons = c('copy', 'csv', 'excel')),
      ...
  )
  if (!is.null(digits)) {
    numeric_cols <- names(df)[sapply(df, is.numeric)]
    return(dt %>% DT::formatRound(columns = numeric_cols, digits = digits))
  }
  return(dt)
}

createNameMapping <- function(names_vector) {
  valid_names <- make.names(names_vector)
  name_mapping <- setNames(valid_names, names_vector)
  return(name_mapping)
}

convertToOriginalNames <- function(valid_names, name_mapping) {
  # Invert the mapping: from valid names to original names
  inverted_mapping <- names(name_mapping)
  names(inverted_mapping) <- name_mapping

  # Use the inverted mapping to get original names
  original_names <- inverted_mapping[valid_names]

  # Replace NA with the valid name itself (for names not in the mapping)
  original_names[is.na(original_names)] <- valid_names[is.na(original_names)]

  return(original_names)
}


move_column_to_index <- function(df, col_name, index) {
  if (!col_name %in% names(df)) {
    stop("Column not found in the dataframe")
  }
  
  if (index < 1 || index > ncol(df)) {
    stop("Index is out of bounds")
  }

  other_cols <- setdiff(names(df), col_name)
  
  if (index == 1) {
    new_order <- c(col_name, other_cols)
  } else {
    new_order <- c(
      other_cols[1:(index - 1)],
      col_name,
      other_cols[index:length(other_cols)]
    )
  }
  
  df[, new_order]
}