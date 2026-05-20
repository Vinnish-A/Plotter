library(magrittr)
library(RColorBrewer)
library(tidyverse)
library(tidygraph)
library(ggraph)
library(ggpubr)
library(cowplot)
library(geomtextpath)

sessionInfo()

df2 <- read_tsv("network_data.tsv") %>% select(3,1) %>% mutate(count=1)

edges1 <- tibble(from="root",to=df2$group %>% unique()) 
edges2 <- df2 %>% select(1,2) %>% set_colnames(c("from","to")) 
edges <- bind_rows(edges1,edges2)

nodes <- tibble(node = c('root',unique(df2$group),unique(df2$ID)))
graph  <- tbl_graph(nodes,edges)

lcc <- create_layout(graph,layout = "dendrogram",circular = TRUE) %>%  
  left_join(.,edges %>% slice(5:n()) %>% select(1,2) %>% 
                    set_colnames(c("group","to")),by=c("node"="to")) %>% 
  mutate(group = case_when(!is.na(group) ~ group,    # 如果已经有 group，保留
    TRUE ~ node)) %>% 
  dplyr::rename("node.branch"="group") %>% 
  mutate(node.size=case_when(
    node %in% c("root","blank_1","blank_2") ~ 0,
    node %in% c("Ctrl","Cis") ~ 20,
    !node %in% c("root","blank_1","blank_2","Ctrl","Cis") ~ 3))

p1 <- ggraph(lcc) + 
  geom_edge_diagonal(aes(color=node1.node.branch),
                     linewidth=0.8,
                     show.legend = F) +
  geom_node_point(aes(color=node.branch,size=I(node.size))) +
  scale_edge_color_manual(values = c("Cis"="grey70","Ctrl"="grey70",
                                     "root"="white","blank_1"="white","blank_2"="white")) +
  scale_color_manual(values =c("Cis"="#5686C3","Ctrl"="#973CB6","root"="white",
                               "blank_1"="white","blank_2"="white")) +
  coord_fixed(clip = "off") +
  annotate(geom="text",x=-0.42,y=-0.26,label="Cis",color="white",size=5)+
  annotate(geom="text",x=0.42,y=0.26,label="Ctrl",color="white",size=5) +
  guides(color="none",size="none") +
  theme_void() +
  theme(plot.margin = margin(0,0,0,0,unit="cm"),
        plot.background = element_blank())


df <- read_tsv("network_data.tsv")

df$ID <- factor(
  df$ID,levels = c(df %>% filter(group=="Ctrl") %>% pull(ID),
                   "blank1","blank2",
                   df %>% filter(group=="Cis") %>% pull(ID),
                   "blank3","blank4"))

p2 <- df %>% ggplot(.,aes(ID,y="HMDB class",fill=`HMDB class`))+
  geom_tile()+
  scale_fill_brewer(palette = "Paired",na.translate = FALSE)+
  coord_radial(start =0,inner.radius = 0.9) +
  theme_void()

p3 <- df %>% ggplot(.,aes(ID,y="Corr coef",fill=`Corr coef`))+
  geom_tile()+
  scale_fill_gradientn(colors = c(
    colorRampPalette(colors = c('#FF7F0080',"white","#FF7F00"))(100)),
    na.value = "white") +
  coord_radial(start =0,inner.radius = 0.9) +
  theme_void()

p4 <- df %>% ggplot(.,aes(ID,y="VIP",fill=VIP))+
  geom_tile()+
  scale_fill_gradientn(colors = c(
    colorRampPalette(colors = c('#e0f3f8','#4575b4'))(100)),
    na.value="white") +
  coord_radial(start =0,inner.radius = 0.9) +
  theme_void()

p5 <- df %>% ggplot(., aes(x=ID,y=Log2FC)) +
  geom_bar(stat="identity",fill=I("grey90")) +
  coord_radial(start =0) +
  scale_y_continuous(limits=c(-20,10),expand=c(0,0)) +
  geom_textpath(data=df %>% filter(group %in% c("Cis","Ctrl")),
                aes(label =ID),angle = 90,hjust =0,size=3,vjust=0.5) +
  theme(axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.title = element_blank(),
        axis.ticks = element_blank(),
        panel.background = element_blank(),
        plot.background = element_blank(),
        panel.grid = element_blank())

p22 <- get_legend(p2)
p33 <- get_legend(p3)
p44 <- get_legend(p4)

plot <- ggdraw() +
  draw_plot(p1,scale = 0.4,x=0,y=0) +
  draw_plot(p2+theme(legend.position = "none"),
            scale = 0.53,x=0,y=0) +
  draw_plot(p3+theme(legend.position = "none"),
            scale=0.59,x=0,y=0)+
  draw_plot(p4+theme(legend.position = "none"),
            scale=0.65,x=0,y=0)+
  draw_plot(p5,scale=1,x=0,y=0)+
  draw_plot(p22,x=-0.45,y=-0.1)+
  draw_plot(p33,x=-0.45,y=0.15)+
  draw_plot(p44,x=-0.55,y=0.15)+
  theme(plot.margin = margin(0,0,0,3,unit="cm"))

plot