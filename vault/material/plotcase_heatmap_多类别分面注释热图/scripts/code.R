library(tidyverse)
library(magrittr)
library(ggtext)
library(ggh4x)

sessionInfo()

# 读入热图的表达矩阵
heat <- read_tsv("heta.tsv",skip = 1) %>% 
  column_to_rownames(var="gene") %>% 
  # 标准化
  scale(,center = T) %>% as.data.frame() %>% 
  rownames_to_column(var="gene")
# 按列构建分组信息
group <- tibble::tribble(
  ~type,        ~group,      ~name,
  "UT",       "empty",  "sample1",
  "4-OHT",       "empty",  "sample2",
  "ADR",       "empty",  "sample3",
  "ADR + 4-OHT",       "empty",  "sample4",
  "UT",   "PU.1-ER<sup>T2</sup>",  "sample5",
  "4-OHT",   "PU.1-ER<sup>T2</sup>",  "sample6",
  "ADR",   "PU.1-ER<sup>T2</sup>",  "sample7",
  "ADR + 4-OHT",   "PU.1-ER<sup>T2</sup>",  "sample8",
  "UT", "C/EBP&beta;-ER<sup>T2</sup>",  "sample9",
  "4-OHT", "C/EBP&beta;-ER<sup>T2</sup>", "sample10",
  "ADR", "C/EBP&beta;-ER<sup>T2</sup>", "sample11",
  "ADR + 4-OHT", "C/EBP&beta;-ER<sup>T2</sup>", "sample12",
  "UT",    "JUN-ER<sup>T2</sup>", "sample13",
  "4-OHT",    "JUN-ER<sup>T2</sup>", "sample14",
  "ADR",    "JUN-ER<sup>T2</sup>", "sample15",
  "ADR + 4-OHT",    "JUN-ER<sup>T2</sup>", "sample16")
# 按行构建分组信息
group2 <- tibble::tribble(
  ~gene,          ~group2,
  "ADR",    "ADR<br>4-OHT",
  "4-OHT",    "ADR<br>4-OHT",
  "IL1B", "SASP/<br>NF-kB",
  "CCL3", "SASP/<br>NF-kB",
  "CCL22", "SASP/<br>NF-kB",
  "LGALS3", "SASP/<br>NF-kB",
  "CXCL10", "SASP/<br>NF-kB",
  "IL6", "SASP/<br>NF-kB",
  "TNFAIP3", "SASP/<br>NF-kB",
  "NFKBIA", "SASP/<br>NF-kB",
  "CD44", "SASP/<br>NF-kB",
  "CDKN1A",  "cell<br>cycle",
  "PCNA",  "cell<br>cycle",
  "LMNB1",  "cell<br>cycle",
  "MYC",  "cell<br>cycle",
  "MS4A1",         "B-cell",
  "CD19",         "B-cell",
  "PAX5",         "B-cell",
  "BACH2",         "B-cell",
  "PRDM1",         "B-cell",
  "CSF1R",        "myeloid",
  "ITGAX",        "myeloid",
  "FCGR2A",        "myeloid",
  "NCF2",        "myeloid",
  "JUN",        "myeloid",
  "CEBPB",        "myeloid",
  "ZEB2",        "myeloid",
  "CD86",            "APC",
  "CIITA",            "APC")

# 给标准化后的表达矩阵添加两行全为0的数据
# 该步主要为后面在图中添加+-符号文本
df <- heat %>% add_row( gene =c("ADR","4-OHT"),
                        !!!as.list(set_names(rep(0, ncol(heat) - 1),
                                             names(heat)[-1]))) %>%
  pivot_longer(-gene)
# 导入+——符号文本信息
label <- read_tsv("type.tsv") %>% pivot_longer(-gene) %>% 
  set_colnames(c("gene","name","text"))
# 将所有数据整合
dff <- df %>% left_join(.,group,by="name") %>% 
  left_join(.,group2,by="gene") %>% 
  left_join(.,label,by=c("gene","name"))


# 定义基因的顺序
dff$gene <- factor(dff$gene,
                   levels = rev(c("ADR","4-OHT","CCL3", 
                                  "CCL22", "LGALS3", 
                                  "CXCL10","IL6","TNFAIP3",
                                  "NFKBIA", "CD44",
                                  "CDKN1A","PCNA","LMNB1",
                                  "MYC","MS4A1", "CD19","PAX5", 
                                  "BACH2","PRDM1","CSF1R","ITGAX", 
                                  "FCGR2A","NCF2", "JUN","CEBPB",
                                  "ZEB2","CD86","CIITA")))
# 定义两个分面的顺序
dff$group <- factor(dff$group,levels = unique(dff$group))
dff$group2 <- factor(dff$group2,levels =unique(group2$group2))

# 定义一个主题
# 其主要目的是将ADR-40HT分面的Y轴文本隐藏
white_axis <- guide_axis(theme = theme(
  axis.text.y = element_blank(),
  axis.ticks = element_blank()))

dff %>% ggplot(aes(name,gene,fill=value))+
  geom_tile() +
  scale_fill_gradient2(high = 'red',
                       mid = 'white',low = '#145afc',midpoint = 0,
                       na.value =NA)+
  scale_x_discrete(expand = c(0,0)) +
  scale_y_discrete(expand = c(0,0),position = "right")  +
  geom_text(data=dff,aes(label=text))+
  # 分面
  facet_grid(group2~group,scale="free",switch = "y") +
  # 设置Y轴每个分面的高度
  force_panelsizes(cols=c(2),rows = c(2,9,4,5,7,2),respect=FALSE)+
  # 隐藏ADR4-OHT分面的文本
  facetted_pos_scales(
    y = list(group2 %in% c("ADR<br>4-OHT") ~ scale_y_discrete(
      guide =  white_axis)))  +
  labs(x=NULL,y=NULL) +
  theme_test()+
  theme(panel.spacing= unit(0,"cm"),
        strip.text.y = element_markdown(face = "bold",color="black"),
        strip.text.x = element_markdown(face = "bold",color="black"),
        strip.background.x = element_rect(fill="white"),
        strip.background.y = element_blank(),
        axis.text.x=element_blank(),
        axis.ticks =element_blank(),
        legend.title = element_blank())

