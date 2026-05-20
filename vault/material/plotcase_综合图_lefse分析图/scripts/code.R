# rm(list=ls())
# install.packages("pacman")
# install.packages("microeco")
pacman::p_load(tidyverse, microeco, magrittr)

sessionInfo()
# 读取特征表 (OTU/ASV 表)，行名为物种/特征 ID
feature_table <- read.csv('feature_table.csv', row.names = 1)

# 读取样本信息表，行名为样本 ID
sample_table <- read.csv('sample_table.csv', row.names = 1)

# 读取分类学注释表，行名为物种/特征 ID
tax_table <- read.csv('tax_table.csv', row.names = 1)

# 用 microtable 包构建一个标准化数据对象，包含样本、OTU/ASV、分类信息
dataset <- microtable$new(sample_table = sample_table,
                          otu_table = feature_table, 
                          tax_table = tax_table)

# 基于lefse做差异分析
lefse <- trans_diff$new(dataset = dataset, method = "lefse", 
                        group = "Group", alpha = 0.01,  # 显著性阈值 0.01
                        lefse_subgroup = NULL)          # 没有设置子组

# 绘制差异物种的 LDA score 柱状图，默认阈值 LDA > 4
lefse$plot_diff_bar(threshold = 4)

# 绘制前 30 个差异物种的 LDA score 柱状图
lefse$plot_diff_bar(use_number = 1:30, width = 0.8, 
                    group_order = c("CW", "IW", "TW")) +
  ggsci::scale_color_npg() +  
  ggsci::scale_fill_npg() 

# 设定显示标签
use_labels <- c("c__Deltaproteobacteria", "c__Actinobacteria", "o__Rhizobiales",
                "p__Proteobacteria", "p__Bacteroidetes", 
                "o__Micrococcales", "p__Acidobacteria", 
                "p__Verrucomicrobia", "p__Firmicutes", 
                "p__Chloroflexi", "c__Acidobacteria", 
                "c__Gammaproteobacteria", "c__Betaproteobacteria", "c__KD4-96",
                "c__Bacilli", "o__Gemmatimonadales", 
                "f__Gemmatimonadaceae", "o__Bacillales", "o__Rhodobacterales")

# 在 cladogram 中绘制 200 个分类单元和前 50 个显著特征
lefse$plot_diff_cladogram(use_taxa_num = 200, 
                          use_feature_num = 50, 
                          select_show_labels = use_labels)


