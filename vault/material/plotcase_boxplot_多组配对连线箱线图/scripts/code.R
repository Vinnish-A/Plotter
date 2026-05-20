library(tidyverse)
library(ggpubr)

# 定义函数

# alternative = “less”，假设是：前一组<后一组，检验的是： 差值 (前一组 − 后一组) 的中位数< 0；
# alternative = “greater”，假设是：前一组 > 后一组，检验的是： 差值 (前一组 − 后一组) 的中位数 > 0；
# 比较 D4 vs D9，如果是 “greater”， 意思是检验D4的丰度大于D9。如果大部分个体都是 D4 > D9，那就会显著。

box_line_plot=function(tmp_df,alternative='less',prefix){
  my_comparisons <- list( c("1", "2"),c("2", "3"),
                          c("3", "4"),c("1", "3"),c("1", "4"))
  p <- ggplot(tmp_df, aes(x = timepoint, y = Relative_frequency)) + 
    geom_boxplot(aes(fill = timepoint),alpha=0.5, width=0.5) +
    geom_line(aes(group = Patient),color='gray45') + 
    geom_point(size = 2, color = 'black')+ 
    theme_classic()+
    theme(legend.position = "none")+
    labs(x="Timepoints",y="Relative frequency") +
    scale_x_discrete(labels=c("D4","D9","D17","D24"))
  if (alternative=='less'){
    p = p + stat_compare_means(
      comparisons = my_comparisons,method = 'wilcox.test',
      method.args = list(alternative = "less"),label = "p.forma")
  } else if (alternative=='greater'){
    p = p + stat_compare_means(
      comparisons = my_comparisons,method = 'wilcox.test',
      method.args = list(alternative = "greater"),label = "p.forma")
  }
  ggsave(file.path(outdir,paste0(prefix,'.pdf')),p,width = 3.5,height = 4.5)
  return(p)
}

cell_abund_sample=read.delim('cell_abundance_sample_timepoint.txt')
outdir="./"
cell_abund_sample=na.omit(cell_abund_sample) # 去除na数据
cell_abund_sample$timepoint=factor(cell_abund_sample$timepoint,levels = c(1,2,3,4))

# CD8 cell 
tmp_df=cell_abund_sample[which(cell_abund_sample$cell_type=='CD8 T'),]
tmp_df=na.omit(tmp_df)
# 绘图
p3_1 <- box_line_plot(tmp_df,alternative='less',prefix='CD8_cell_all_sample')

# CD4 cell 
tmp_df=cell_abund_sample[which(cell_abund_sample$cell_type=='CD4 T'),]
tmp_df=na.omit(tmp_df)
p3_2 <- box_line_plot(tmp_df,alternative='less',prefix='CD4_cell_all_sample')

# B cell 
tmp_df=cell_abund_sample[which(cell_abund_sample$cell_type=='B cell'),]
tmp_df=na.omit(tmp_df)
p3_3 <- box_line_plot(tmp_df,alternative='less',prefix='b_cell_all_sample')

# Neutrophil cell 
tmp_df=cell_abund_sample[which(cell_abund_sample$cell_type=='Neutrophil'),]
tmp_df=na.omit(tmp_df)
p3_4 <- box_line_plot(tmp_df,alternative='greater',prefix='Neutrophil_all_sample')

# 拼图
library(patchwork)
p3_1|p3_2|p3_3|p3_4