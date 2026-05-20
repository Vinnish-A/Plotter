# devtools::install_github("davidsjoberg/ggsankey")
# devtools::install_local("ggsankey-main.zip")
library(ggsankey)
library(tidyverse)

data <- read.table("GO_enrichment_stat.txt", header = T)

set.seed(123)
# 随机选10个通路，25个基因
term_select <- data[sample(1:nrow(data), 10), ]
term_select <- term_select[order(term_select$qvalue, decreasing = T),]
term_select$ID <- factor(term_select$ID, levels = term_select$ID)
gene_ID <- str_split(term_select$geneID, "/")

# 设置每个通路选几个基因的向量：
select_num <- sample(1:3, 10, replace = T)
sankey_data <- data.frame(GO = rep(term_select$ID, select_num),
                          Gene = NA)

n <- 1
for (i in 1:10) {
  num <- select_num[i]
  sankey_data$Gene[n:(n+num-1)] <- sample(gene_ID[[i]], num)
  n <- n+num
}

gene_select <- sankey_data$Gene

# 转换为绘制桑基图的格式：
sankey_data <- sankey_data %>%
  make_long(Gene, GO)

# 修改节点顺序：
sankey_data$node <- factor(sankey_data$node,
                           levels = c(as.character(term_select$ID) %>% unique(),
                                      gene_select %>% unique()))

library(cols4all)
mycol <- c4a('rainbow_wh_rd', length(unique(sankey_data$node)))

p1 <- ggplot(sankey_data, aes(x = x,
               next_x = next_x,
               node = node,
               next_node = next_node,
               fill = node,
               label = node)) +
  geom_sankey(flow.alpha = 0.5,
              flow.fill = 'grey',
              # flow.color = 'grey80', #条带描边色
              node.fill = mycol, #节点填充色
              smooth = 8,
              width = 0.1) +
  geom_sankey_text(size = 2, hjust = 1.4,
                   color = "black")+
  theme_void() +
  theme(legend.position = 'none')


####### 气泡图 --------------
go_data <- term_select %>%
  mutate(ymax = cumsum(select_num)) %>% #ymax为Width列的累加和
  mutate(ymin = ymax - select_num) %>%
  mutate(label = (ymin + ymax)/2) #取xmin和xmax的中心位置作为标签位置
head(go_data)

p2 <- ggplot(go_data) +
  geom_point(aes(x = -log10(qvalue),
                 y = label, #替换y轴列为数值
                 size = Count,
                 color = -log10(qvalue))) +
  scale_size_continuous(range=c(2, 5)) + #调整气泡大小范围(默认尺寸部分过小)
  scale_colour_distiller(palette = "Reds", direction = 1) + #更改配色
  scale_y_continuous(expand = expansion(mult = 0, add = c(0.8, 0.3)))+
  labs(x = "-log10(qvalue)",
       y = "") +
  theme_bw()+
  theme(axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        plot.background = element_blank(),
        text = element_text(size = 7))

p2

# 拼图：
library(cowplot)

p <- ggdraw() +
  # 四个数值中前两个代表左下角位置：
  # 后两个代表图形宽和高：
  draw_plot(p1, 0, 0, .8, 1)+
  draw_plot(p2, 0.6, 0.03, .4, 0.88)

pdf("plot.pdf", height = 5, width = 7)
p
dev.off()

