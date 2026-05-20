# devtools::install_github("junjunlab/ClusterGVis",force = TRUE)
library(ClusterGVis)
library(tidyverse)
sessionInfo()

data(exps)

cm <- clusterData(obj = exps,
                  clusterMethod = "mfuzz",
                  clusterNum = 8)
markGenes = rownames(exps)[sample(1:nrow(exps),30,replace = F)]

ann_res_df <- data.frame(id=c(rep('C1',3),rep('C3',3),rep('C8',4)),
                         term=c('mRNA processing','DNA replication',
                                'mitochondrial gene expression',#C1
                                'immunoglobulin production','B cell mediated immunity',
                                'protein-RNA complex assembly',#C3
                                'immune response','myeloid leukocyte activation',
                                'neutrophil activation','chemokine production'#C8
                         ))


visCluster(object = cm,
           plotType = "both",
           lineSide = "left",
           column_names_rot = 45,
           markGenes = markGenes,
           annoTermData = ann_res_df)

