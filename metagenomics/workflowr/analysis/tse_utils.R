# Some utilities for working with TreeSummarizedExperiment

library(TreeSummarizedExperiment)
# library(rlang)
# source("analysis/nfcore_mag_utils.R")


dropCondition <- function(tse, column_name, condition_to_drop) {
  # Convert the quosure to a string
  column_name_str <- as.character(rlang::enexpr(column_name))
  
  # Identify features that are non-zero exclusively in the condition_to_drop
  exclusive_features <- rowSums(assay(tse[, colData(tse)[[column_name_str]] == condition_to_drop])) > 0 &
    rowSums(assay(tse[, colData(tse)[[column_name_str]] != condition_to_drop])) == 0

  # Drop the condition
  tse <- tse[, colData(tse)[[column_name_str]] != condition_to_drop]
  # Update factor levels
  colData(tse)[[column_name_str]] <- droplevels(colData(tse)[[column_name_str]])

  # Drop the features that were unique to that condition
  tse <- tse[!exclusive_features, ]

  return(tse)
}

minCounts <- function(tse, minCounts) {
  features_to_keep <- rowMaxs(assay(tse, "counts")) >= minCounts
  return(tse[features_to_keep, ])
}

summaryStats <- function(df) {
  data.frame(
    taxon = rownames(df),
    mean = rowMeans(df, na.rm=TRUE),
    sd = matrixStats::rowSds(as.matrix(df), na.rm=TRUE)
  )
}

tseGroupSummaryStats <- function(se, assay_name, group_col) {
  assay_data <- assay(se, assay_name)
  group_info <- colData(se)[[group_col]]

  group_stats_list <- lapply(unique(group_info), function(g) {
    subsetted_data <- assay_data[, group_info == g]
    group_stats <- summaryStats(subsetted_data)

    colnames(group_stats)[which(colnames(group_stats) == "mean")] <- paste0(g, "_", assay_name, "_mean")
    colnames(group_stats)[which(colnames(group_stats) == "sd")] <- paste0(g, "_", assay_name, "_sd")
    return(group_stats)
  })

  # Combine results from the list into a single data frame
  results <- Reduce(function(x, y) merge(x, y, by = "taxon", all = TRUE), group_stats_list)
  rownames(results) <- results$taxon

  return(results)
}

twenty_colors_two <- paste0(
  "2f4f4f,2e8b57,7f0000,000080,9acd32,",
  "ff0000,ff8c00,ffd700,00ff00,00fa9a,4169e1,00ffff,00bfff,0000ff,",
  "da70d6,d8bfd8,ff00ff,eee8aa,ff1493,ffa07a"
)

# https://microbiome.github.io/miaViz/reference/plotAbundance.html
taxa_barplot <- function(tse, taxa.level, group = "group", 
                         assay.type = "relabundance", n_top = 10, 
                         add_legend = TRUE, 
                         show_group_legend = TRUE,
                         font_size=8) {
  tse_glom <- mia::agglomerateByRank(tse, rank = taxa.level, onRankOnly = TRUE)
  rownames(tse_glom) <- rowData(tse_glom)[[taxa.level]]
  top_taxa <- mia::getTopFeatures(
    tse_glom,
    top = min(nrow(rowData(tse_glom)), n_top),
    assay.type = assay.type
  )

  minor_renamed <- lapply(
    rowData(tse_glom)[[taxa.level]],
    function(x) {
      if (x %in% top_taxa) {
        x
      } else {
        "Other"
      }
    }
  )

  rowData(tse_glom)[[taxa.level]] <- as.character(minor_renamed)

  # Create colour palette
  pal <- paste0("#", stringr::str_split(twenty_colors_two, ",") |> unlist())
  pal <- append(pal, "#666666")

  # Initial barplot used miaViz default colours
  # We create this just so we have the list for plot[[1]] and plot[[2]]
  plot <- miaViz::plotAbundance(
    tse_glom,
    assay.type = assay.type,
    rank = taxa.level,
    features = group,
    order_sample_by = group,
    order_rank_by = "abund",
    add_legend = add_legend,
  )

  # Replace the top barplot with one using our colours
  # We keep the bottom section with sample groupings
  plot[[1]] <- (miaViz::plotAbundance(
    tse_glom,
    assay.type = assay.type,
    rank = taxa.level,
    features = group,
    order_sample_by = group,
    order_rank_by = "abund",
    # order_sample_by = "Other",
    add_legend = add_legend,
    add_x_text = TRUE,
  )[[1]]
  + theme(
      axis.text.x = element_text(angle = 90, size = font_size),
      axis.title.x = element_blank(),         # Remove the x-axis title, we get this from the grouping
      axis.text.y = element_text(size = font_size),
      legend.text = element_text(size = font_size),
      legend.title = element_blank(), # element_text(size = font_size),
      plot.title = element_text(size = font_size),
      plot.subtitle = element_text(size = font_size),
      plot.caption = element_text(size = font_size),
      strip.text = element_text(size = font_size),
      legend.key.size = unit(0.6, "lines"),  # Adjust the size of legend keys
      legend.spacing = unit(0.6, "lines"),    # Adjust the spacing between legend items
    )
    + scale_fill_manual(values = pal)
    + scale_color_manual(values = pal)
    + guides(fill = guide_legend(ncol = 1), color = guide_legend(ncol = 1))
  )

  # Move the group legend to the right-hand side
  # plot[[2]] <- plot[[2]] + theme(legend.position = "right")

  plot[[2]] <- plot[[2]] + theme(legend.key.size = unit(0.6, "lines"), 
                                 legend.spacing = unit(0.6, "lines"))

  if (!show_group_legend) {
    return(plot[[1]])
  }

  plots <- patchwork::wrap_plots(plot, ncol = 1, heights = c(0.95, 0.05))

  return(plots)
}

# For whatever reason (possibly missing NCBI_tax_id column) the
# mia::loadFromMetaphlan() function won't work on my metaphlan4 merged table
# so we use this
loadFromMetaphlan4 <- function(fn, groups = NULL, sep = "|", column_suffix = "_metaphlan") {
  df <- as.data.frame(readr::read_tsv(fn, skip = 1))
  # df$classifcation <- df$clade_name
  rownames(df) <- df$clade_name

  # Remove the '_metaphlan' suffix from column names, divide all values by 100
  df <- df %>%
    rename_with(~ gsub(column_suffix, "", .x)) %>%
    mutate(across(where(is.numeric), ~ .x / 100))

  relab <- df %>% select(!c(clade_name))
  relab <- as.matrix(relab)

  # Split the clades k__Bacteria|p__Actinobacteria|c__Actinobacteria
  # into seperate columns
  taxa_labels <- df %>%
    select(clade_name) %>%
    rowwise() %>%
    do(bind_cols(., split_taxonomy_str(.$clade_name, sep = sep)))

  if (!is.null(groups)) {
    tse <- TreeSummarizedExperiment(
      assays = SimpleList(
        relabundance = relab
      ),
      colData = groups,
      rowData = taxa_labels
    )
  } else {
    tse <- TreeSummarizedExperiment(
      assays = SimpleList(
        relabundance = relab
      ),
      rowData = taxa_labels
    )
  }

  return(tse)
}

loadFromMetaphlan4GTDB <- function(fn, groups = NULL, column_suffix = "_metaphlan-gtdb") {
  return(loadFromMetaphlan4(fn, groups = groups, column_suffix = column_suffix, sep = ";"))
}

rename_col <- function(d, old, new) {
  d[[new]] <- d[[old]]
  d[[old]] <- NULL
  return(d)
}

loadFromMetaphlanSingle <- function(fn, sample_name, 
                                    sep = ";", 
                                    column_suffix = "_metaphlan", 
                                    skip = 5, 
                                    zero.nas=TRUE) {

  # TODO: We should detect the number of # headers and skip all but the last (which is the real column header)
  df <- as.data.frame(readr::read_tsv(fn, skip = skip))
  df$clade_name <- df[["#clade_name"]]
  df[["#clade_name"]] <- NULL

  # With files converted to GTDB taxonomy, we can have some identical clade_names
  # (presumably some unique SGBs map to a single GTDB species).
  # We sum the columns for these identical clade_names so that every clade_name is unique
  cols_to_collapse <- setdiff(names(df), c("clade_name", "clade_taxid"))
  df <- df %>%
    group_by(clade_name) %>%
    summarise(across(all_of(cols_to_collapse), sum))
  
  rownames(df) <- df$clade_name
  
  # Remove the '_metaphlan' suffix from column names, divide all values by 100
  df$relative_abundance <- (as.numeric(df$relative_abundance) / 100)

  relab <- df %>%
    dplyr::select(c(relative_abundance))
  relab <- rename_col(relab, "relative_abundance", sample_name)
  relab <- as.matrix(relab)
  if (zero.nas) {
    relab[is.na(relab)] <- 0
  }
  rownames(relab) <- df$clade_name

  assays <- SimpleList(relabundance = relab)

  # The default gtdb converted metaphlan output is missing non-default columns.
  # We use a modified verison of https://github.com/biobakery/MetaPhlAn/blob/master/metaphlan/utils/sgb_to_gtdb_profile.py
  # that includes the extra columns: coverage, estimated_number_of_reads_from_the_clade

  if ("coverage" %in% colnames(df)) {
    coverage <- df %>%
      dplyr::select(c(coverage))
    coverage <- rename_col(coverage, "coverage", sample_name)
    coverage <- as.matrix(coverage)
    if (zero.nas) {
      coverage[is.na(coverage)] <- 0
    }
    assays$depth <- coverage
    rownames(coverage) <- df$clade_name
  }

  if ("estimated_number_of_reads_from_the_clade" %in% colnames(df)) {
    n_reads <- df %>%
      dplyr::select(c(estimated_number_of_reads_from_the_clade))
    r_nreads <- rename_col(n_reads, "estimated_number_of_reads_from_the_clade", sample_name)
    n_reads <- as.matrix(n_reads)
    if (zero.nas) {
      n_reads[is.na(n_reads)] <- 0
    }
    assays$counts <- n_reads
    rownames(n_reads) <- df$clade_name
  }

  taxa_labels <- df %>%
    dplyr::select(clade_name) %>%
    rowwise() %>%
    do(bind_cols(., split_taxonomy_str(.$clade_name, sep = sep)))

  taxa_labels <- as.data.frame(taxa_labels)
  #taxa_labels$clade_taxid <- df$clade_taxid
  rownames(taxa_labels) <- df$clade_name

  tse <- TreeSummarizedExperiment(
    assays = assays,
    rowData = taxa_labels
  )

  return(tse)
}
