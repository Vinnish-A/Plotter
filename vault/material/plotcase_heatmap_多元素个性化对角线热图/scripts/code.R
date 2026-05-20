library(tidyverse)
# install.packages("devtools")
#devtools::install_github("junjunlab/jjPlot")
library(jjPlot)
library(ggnewscale)

sessionInfo()

df <- read_tsv("data.tsv") 

dff <- df %>% rownames_to_column(var="id") %>%  # 将行名转换为id列
  as_tibble() %>%  # 转换为tibble数据框
  mutate(EGFR=as.character(EGFR),  # 将EGFR列转换为字符型
    Recurrence=as.character(Recurrence),  # 将Recurrence列转换为字符型
    Smoking_status=as.character(Smoking_status),  # 将Smoking_status列转换为字符型
    Sample_no=as.character(Sample_no)) %>% # 将Sample_no列转换为字符型
  pivot_longer(-id)
# 将name列转换为因子，并按唯一值的逆序排序
dff$name <- factor(dff$name, levels = dff$name %>% unique() %>% rev())  

plot <- dff %>% 
  # 过滤掉指定列
  filter(!name %in% c("Pretreatment_detectio2",
                      "Postoperative_detection2")) %>% 
  ggplot(aes(id,name))+
  # 绘制灰色方块
  geom_tile(color="white",fill="grey90",size=1)+
  scale_x_discrete(expand = c(0,0))+
  scale_y_discrete(expand = c(0,0))+
  # 绘制Stage列的文本标签
  geom_text(data=dff %>% filter(name=="Stage"),
            aes(id,name,label = value),inherit.aes = F)+
  # 绘制Sample_no列的文本标签
  geom_text(data=dff %>% filter(name=="Sample_no"),
            aes(id,name,label = value),inherit.aes = F)+
  # 绘制Smoking_status、EGFR和Recurrence列的点
  geom_point(data=dff %>% filter(name %in% c("Smoking_status","EGFR","Recurrence")) %>% 
               filter(value !="1"),
             aes(id,name,color = value),inherit.aes = F,
             shape=19,size=5,show.legend = F)+
  scale_color_manual(values = "black")+
  # 添加Treatment行的色块
  geom_point(data=dff %>% filter(name %in% c("Treatment")) %>% 
               dplyr::rename("Treatment"="value"),
            aes(id,name,fill = Treatment),inherit.aes = F,shape=22,size=11,color="grey90")+
  scale_fill_manual(values = c("#F98400","#9986A5"))+
  new_scale_fill()+
  # 添加Histology行的色块
  geom_point(data=dff %>% filter(name %in% c("Histology")) %>% 
               dplyr::rename("Histology"="value"),
             aes(id,name,fill = Histology),inherit.aes = F,shape=22,size=11,color="grey90")+
  scale_fill_manual(values = c("#E6A0C4","#6C8645","#CCC591"))+
  new_scale_fill()+
  # 绘制Pretreatment_detectio & Pretreatment_detectio2行的对角线色板
  # 左右分开添加，因此需要四段代码
  geom_jjtriangle(
    data=dff %>% filter(name %in% c("Pretreatment_detectio",
                                    "Pretreatment_detectio2")) %>% 
      pivot_wider(names_from = "name") %>% 
      mutate(name="Pretreatment_detectio") %>% 
      filter(Pretreatment_detectio !="NA") %>% 
      dplyr::rename("Detection"="Pretreatment_detectio"),
    aes(id,name,fill =Detection),type = 'ul',color="white",size=0.5) +
  
  geom_jjtriangle(data=dff %>% filter(name %in% c("Pretreatment_detectio",
                                                  "Pretreatment_detectio2")) %>% 
                    pivot_wider(names_from = "name") %>% 
                    mutate(name="Pretreatment_detectio") %>% 
                    filter(Pretreatment_detectio !="NA"),
                  aes(id,name,fill =Pretreatment_detectio2),type = 'br',
                  color="white",size=0.5)+
  geom_jjtriangle(data=dff %>% filter(name %in% c("Postoperative_detection",
                                                  "Postoperative_detection2")) %>% 
                    pivot_wider(names_from = "name") %>% 
                    mutate(name="Postoperative_detection") %>% 
                    filter(Postoperative_detection !="NA"),
                  aes(id,name,fill =Postoperative_detection),type = 'ul',
                  color="white",size=0.5)+
  geom_jjtriangle(data=dff %>% filter(name %in% c("Postoperative_detection",
                                                  "Postoperative_detection2")) %>% 
                    pivot_wider(names_from = "name") %>% 
                    mutate(name="Postoperative_detection") %>% 
                    filter(Postoperative_detection !="NA"),
                  aes(id,name,fill =Postoperative_detection2),type = 'br',
                  color="white",size=0.5)+
  scale_fill_manual(values = c("#7294D4","#0A9F9D"))+
  # 定义Detection图例水平布局
  guides(fill=guide_legend(theme=theme(legend.direction = "horizontal",
                                       legend.title.position = "top",
                                       legend.key.height = unit(0.8,"cm"),
                                       legend.key.width = unit(0.8,"cm"))
                           ))+
  theme(legend.background = element_blank(),
        legend.key = element_blank(),
        axis.ticks = element_blank(),
        axis.text.x=element_blank(),
        axis.title = element_blank(),
        axis.text.y=element_text(color="black",size=9,face="bold"),
        legend.key.spacing.y  = unit(-0.3,"cm"),
        legend.text = element_text(color="black",size=9,
                                   margin = margin(c(l=0),unit="cm")),
        plot.margin = margin(c(0.5,0.2,0.5,0.5), unit="cm"),
        legend.spacing.y = unit(0,"cm"),
        legend.title = element_text(color="black",size=9,face="bold",
                                    margin = margin(c(t=0,b=0),unit="cm")))
plot

ggsave(plot,file="heatmap.pdf",width=9.59,height = 3.69,unit="in",dpi=300)
