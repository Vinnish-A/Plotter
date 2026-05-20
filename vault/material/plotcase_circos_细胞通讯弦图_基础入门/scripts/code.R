if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

BiocManager::install("CCPlotR")

library(CCPlotR)

sessionInfo()

data(toy_data, toy_exp, package = 'CCPlotR')

cc_circos(toy_data, option = 'B', n_top_ints = 10)

cc_circos(toy_data, option = 'C', n_top_ints = 15, 
          exp_df = toy_exp,
          cell_cols = c(
            `B` = 'hotpink', `NK` = 'orange',`CD8 T` = 'cornflowerblue'),
          palette = 'PuRd')
