library(ggrepel)
library(tidyverse)
devtools::install_github("biostatsPMH/swimplot", ref="pattern")
library(swimplot)
library(ggnewscale)

sessionInfo()

# 数据处理是绘制该图的关键，下面两段代码需要稍微关注一下，如此进行数据定义是为了
# 符合swimplot包所需的数据格式。下方代码中将PPP2R1A_mutation中的0改为1，
# 其余该为0则是为了调整条带顺序。如此修改后在图中PPP2R1Amut所填充的条带会
# 从顶部开始展示。因为在绘图代码中通过定义id_order=’PPP2R1A_mutation’来调整顺序，
# 绘图逻辑则是由下到上先0后1.

OCCC_response_endpoint <- read.csv("Response_outcome_endpoint.csv") %>% 
  mutate(Genetic=case_when(PPP2R1A_mutation==1 ~"PPP2R1Amut",
                           AKT_alteration==1 ~ "AKTalt",
                           TRUE ~ "No")) %>% 
  mutate(PPP2R1A_mutation=case_when(PPP2R1A_mutation==0 ~1,
                                    TRUE ~ 0))

OCCC_response_timeline <- read.csv("./Response_outcome.csv") %>% 
  mutate(overallResponse=case_when(overallResponse=="Ongoing" ~ NA,
                                   TRUE ~ overallResponse))

arm_plot <- swimmer_plot(df=OCCC_response_endpoint,id='Acc',
                         end='Time_mo',name_fill='Genetic',
                         id_order='PPP2R1A_mutation',
                         increasing=F, col="black",alpha=1,width=.8)

# 下方代码中最主要的就是通过swimmer_arrows添加顶部箭头，
# 只对overallResponse==“Ongoing”的进行添加因此需先进行数据转化 。
# 重新生成1列Genetic2定义overallResponse==“Ongoing” 定义为1，其余为NA。
# arrow_positions = c(0.1,3),控制箭头的长度

p2 <- arm_plot + 
  swimmer_points(df_points= OCCC_response_timeline,id='Acc',
                          time='Time_mo',fill="white",
                          name_shape = 'overallResponse',size=2)+
  swimmer_arrows(df_arrows=OCCC_response_endpoint %>% 
                   mutate(Genetic2=case_when(overallResponse=="Ongoing" ~1,
                                             TRUE ~ NA)),
                 id='Acc',arrow_start='Time_mo',
                 arrow_positions = c(0.1,3),
                 name_col="Genetic",
                 cont="Genetic2",
                 length = 0.1,color="#3B4992FF",
                 show.legend=FALSE,type="open",cex=0.7)+
           scale_y_continuous(breaks = c(0,6,12,18,24,30,36,42,48,54,60,66,72))+
           scale_fill_manual(name="Genetic",
                             values=c("AKTalt"="#8fd2c4","No"="#9bc1dd",
                                      "PPP2R1Amut"='#fdc583'))+
           scale_shape_manual(name="overallResponse",
                              values=c(PD=17,SD=16,PR=15,CR=23,Death=3),
                              breaks=c('PD','SD','PR','CR',"Death"))+
  theme(axis.text.y=element_blank(),
        axis.title = element_blank(),
        axis.ticks.y=element_blank())

anno_df <- read_tsv("anno_df.tsv") %>% 
  mutate(Acc=as.character(Acc))

# 由于热图每一列都有对应的图例，因此分3个图层来进行同时配合new_scale_fill使用。
p1 <- ggplot()+
  geom_tile(data=anno_df %>% select(1,3) %>% 
              mutate(Clinical_trial="Clinical_trial"),
            aes(Clinical_trial,Acc,fill=Clinical),color=I("white"),
            linewidth=1)+
  scale_fill_manual(values = c("black","#6996e3")) +
  new_scale_fill() +
  geom_tile(data=anno_df %>% select(1,4) %>% 
              mutate(Treatment_arm="Treatment_arm"),
            aes(Treatment_arm,Acc,fill=Treatment),color=I("white"),
            linewidth=1)+
  scale_fill_manual(values = c("#95c36e","#075149ff")) +
  new_scale_fill() +
  geom_tile(data=anno_df %>% select(1,5) %>% 
              mutate(ARID1A_mut="ARID1A_mut"),
            aes(ARID1A_mut,Acc,fill=ARID1A),color=I("white"),
            linewidth=1)+
  scale_fill_manual(values = c("#d8443c","#eb7926")) +
  theme(axis.text.x=element_text(color="black",angle=90,
                                 vjust=0.5,hjust=1),
        axis.title=element_blank(),
        plot.margin = margin(0.5,0.5,0.5,0.5,unit="cm"),
        panel.background = element_blank(),
        legend.background = element_blank(),
        axis.ticks = element_blank())

library(aplot)  # 拼图

p2 %>% insert_left(p1,width = c(0.5,5))