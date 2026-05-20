library(tidyverse)
library(ggtree)
library(ggtreeExtra)
library(ggnewscale)
library(ape)
library(MetBrewer)
library(RColorBrewer)

sessionInfo()

# 导入数据
df <- read_csv("data.csv") %>% dplyr::rename(tax=`...1`) %>% 
  column_to_rownames(var="tax")
# 邻接法根据距离矩阵构建聚类树
tree <- dist(df) %>% ape::bionj()

# 绘制基础树图
ggtree(tree,branch.length = "none",
       layout = "circular",
       linetype=1,size=0.5,ladderize = T)+
  theme_void()+
  # 查看节点信息
  geom_text2(aes(subset = !isTip, label = node), hjust = -0.3, vjust = 0.5, size = 3)

# 根据节点信息进行分组
tree2 <- groupClade(tree, c(128,130,133,139,181))

# 绘制基础树
p <- ggtree(tree2, aes(color=group),branch.length = "none",
       layout = "circular",linetype=1,size=0.5,ladderize = T)
  layout_fan(angle = 100)+theme_void()
# 获取树标签
get_taxa_name(p)
# 导入注释信息表
deseq <- read_tsv("DEseq.tsv") %>% mutate(name=as.factor(name))

data2 <- df %>% rownames_to_column(var="ID") %>%
  select(ID,starts_with("n")) %>% 
  pivot_longer(-ID)

data3 <- data2 %>% filter(name %in% c("nap","nif"))

ggtree(tree2, aes(color=group),branch.length = "none",
       layout = "circular",linetype=1,size=0.5,ladderize = T)+
  layout_fan(angle = 10)+
  scale_color_brewer(palette='Paired',breaks=1:5)+
  guides(color="none")+
  new_scale_fill()+
  # 绘制第一圈注释
  geom_fruit(data=deseq,geom=geom_bar,
             mapping=aes(y=sample, x=name,fill=name),
             orientation="y",pwidth=0,stat="identity")+
  scale_fill_manual(values=c("#3C5488FF","#00A087FF"))+
  new_scale_fill()+
  # 绘制第二圈注释
  geom_fruit(data=data2, geom=geom_tile,
             mapping=aes(y=ID, x=name,alpha=value,fill=name),
             color = "black",offset = 0.03,size = 0.08)+
  scale_fill_manual(values=met.brewer("Derain"))+
  guides(alpha="none")+
  new_scale_fill()+
  # 最外圈注释
  geom_fruit(data=data3,geom=geom_bar,
             mapping=aes(y=ID, x=value,fill=name),
             offset = 0.05,pwidth = 0.25,
             orientation="y", 
             stat="identity")+
  scale_fill_manual(values=c("#7294D4", "#F1BB7B"))+
  theme(legend.title = element_blank(),
        legend.background = element_blank(),
        legend.key.height = unit(0.4,"cm"))+
  # 添加外部条带
  geom_strip("301_15-AUS4-Termitinae-Amitermes_meridionalis",
             "229_01-HSRNA1-Archotermopsidae-Hodotermopsissjosdedti",
             label ="Clade1",
             offset = 16, barsize = 3,
             extend = 0.5, color = "#A6CEE3",fontsize = 4,
             hjust = "center",align = T,offset.text = 2,angle = -60)+
  geom_strip("301_09-87-Rhinotermitidae-Coptotermes_elisae",
             "229_08-Cryp-Cryptocercidae-Cryptocercus_punctulatus",
             label ="Clade2",
             offset = 16, barsize = 3,
             extend = 0.5, color = "#1F78B4",fontsize = 4,
             hjust = "center", align = T,offset.text = 2, angle = -25)+
  geom_strip("272_06-AUS110-Kalotermitidae-Cryptotermes_primus",
             "301_36-BRA9-Syntermitinae-Rhynchotermes_nasutissimus",
             label ="Clade3",
             offset = 16, barsize = 3,
             extend = 0.5, color = "#B2DF8A",fontsize = 4,
             hjust = "center", align = T,offset.text = 2, angle = 20)+
  geom_strip("301_12-AUS121-Rhinotermitidae-Heterotermes_sp_4",
             "272_105-US10-Kalotermitidae-Incisitermes_snyderi",
             label ="Clade4",
             offset = 16, barsize = 3,
             extend = 0.5, color = "#33A02C",fontsize = 4,
             hjust = "center", align = T,offset.text = 2, angle = 85) +
  geom_strip("301_22-BRA14-Syntermitinae-Cyrilliotermes_sp",
             "272_32-CIVT017-Nasutitermitinae-Mimeutermes_sorex",
             label ="Clade5",
             offset = 16, barsize = 3,
             extend = 0.5, color = "#FB9A99",fontsize = 4,
             hjust = "center", align = T,
             offset.text = 2, angle = 10)