# Cleaup the GenomeBinning/bin_summary.tsv file
cleanup_bin_summary <- function(df, coassembly = TRUE) {
    # Cleaning up column names ...

    # Remove the _Sn_L001 suffix
    df <- df %>%
        rename_with(~ sub("_S\\d+_L001$", "", .))

    # Drop pointless column
    df[, 1] <- NULL

    # Change '#' to n
    colnames(df) <- gsub("\\#", "n", colnames(df))

    # Change '%' to percent.
    colnames(df) <- gsub("\\%", "percent.", colnames(df))

    # Collapse multiple spaces to dots
    colnames(df) <- gsub("\\s+", ".", colnames(df))

    # Then do the 'universal' column name fix
    colnames(df) <- vctrs::vec_as_names(colnames(df), repair = "universal")

    # Then collapse multple dots
    colnames(df) <- gsub("\\.+", ".", colnames(df))

    # Then remove trailing dots
    colnames(df) <- gsub("\\.$", "", colnames(df))

    # Then all dots to underscores
    colnames(df) <- gsub("\\.", "_", colnames(df))

    # Make all column names lowercase
    names(df) <- tolower(names(df))

    # Ensure all column names are unique before we start mutating
    names(df) <- make.unique(names(df))

    # Split filenames to add some columns
    df <- df %>%
        mutate(assembler = str_split(bin, "-", simplify = TRUE)[, 1])

    df <- df %>%
        mutate(binner = str_split(bin, "-", simplify = TRUE)[, 2])

    df <- df %>%
        mutate(refined = str_detect(binner, "Refined$"))

    df <- df %>%
        mutate(group = str_split(bin, "-", simplify = TRUE)[, 4]) %>%
        mutate(group = str_split(group, "\\.", simplify = TRUE)[, 1]) %>%
        mutate(group = str_split(group, "_", simplify = TRUE)[, 1])

    # Single-sample assemblies use some different naming
    if (!coassembly) {
        # In a non-coassembly this field is 'group'
        df <- df %>%
            mutate(group = str_split(bin, "-", simplify = TRUE)[, 3])

        # In non-coassemblies each row is also associated with a single sample
        df <- df %>%
            mutate(
                sample = str_split(bin, "-", simplify = TRUE)[, 3:4] %>%
                    apply(1, paste, collapse = "-"),
                sample = str_remove(sample, "_.*")
            )
    }

    # Harmonize bin ID field
    if ("genomebin" %in% names(df)) {
        df <- df %>% mutate(bin_id = str_remove(genomebin, ".fa$"))
    }

    # Rename CheckM fields _0,_1 etc to marker_count_0 etc
    f <- stringr::str_glue
    for (n in seq(0,5)) {
        cn <- f("_{n}")
        if (cn %in% names(df)) {
            df[[f("marker_count_{n}")]] <- df[[cn]]
            df[[cn]] <- NULL
        }
    }

    return(df)
}

cleanup_coverm <- function(df) {
    # Nested function to clean individual column names
    clean_column_name <- function(col_name) {
        col_name <- tolower(col_name) # Convert to lowercase
        col_name <- gsub(" \\(%\\)", "", col_name) # Remove " (%)"
        col_name <- gsub("\\.fastq\\.gz", "", col_name) # Remove ".fastq.gz"
        col_name <- gsub("_s[0-9]+_l001", "", col_name) # Remove "_S#_L001" pattern
        # Remove "host_removed.unmapped_1"
        col_name <- gsub("host_removed\\.unmapped_1", "", col_name)
        col_name <- gsub(" ", "_", col_name) # Replace spaces with underscores
        col_name <- gsub("-", "_", col_name) # Replace dashes with underscores
        col_name <- gsub("\\.", "_", col_name) # Replace dots with underscores
        col_name <- gsub("_+", "_", col_name) # Remove consecutive underscores
        return(col_name)
    }

    colnames(df) <- sapply(colnames(df), clean_column_name)
    return(df)
}

# Split strings like:
# split_taxonomy_str("d__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Burkholderiales;f__Burkholderiaceae;g__Turicimonas;s__Turicimonas muris")
# into a data.frame
split_taxonomy_str <- function(tax_string, sep=";") {
  # Mapping for taxonomic levels
  taxonomic_mapping <- c(
    'd' = 'Domain',
    'k' = 'Kingdom',
    'p' = 'Phylum',
    'c' = 'Class',
    'o' = 'Order',
    'f' = 'Family',
    'g' = 'Genus',
    's' = 'Species',
    't' = 'Strain'
  )

  # Create an empty data frame to hold the results
  tax_df <- as.data.frame(matrix(ncol = length(taxonomic_mapping), nrow = 1))
  colnames(tax_df) <- taxonomic_mapping

  if (is.na(tax_string) || tax_string == "") {
    return(tax_df)
  }

  # Split the string by the separator
  tax_list <- strsplit(tax_string, sep, fixed = TRUE)[[1]]

  # Extract the prefixes and names
  prefixes <- gsub("__.*$", "", tax_list)
  names <- gsub("^[a-z]__", "", tax_list)

  # Replace all empty or whitespace-only strings with NA
  names[names == ""] <- NA

  # Populate the dataframe based on the mapping
  for (i in seq_along(prefixes)) {
    col_name <- taxonomic_mapping[prefixes[i]]
    if (!is.null(col_name)) {
      tax_df[[col_name]] <- names[i]
    }
  }

  return(tax_df)
}

find_dupe_cols <- function(df) {
    duplicate_columns <- which(duplicated(names(df)) | duplicated(names(df),
        fromLast = TRUE
    ))
    # Extract the names of duplicate columns
    duplicate_column_names <- names(df)[duplicate_columns]
    return(duplicate_column_names)
}
