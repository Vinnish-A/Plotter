library(tidyverse)
library(ggh4x)

sessionInfo()

sub_merge <- read_tsv("data.txt")

sub_merge$Compartments <- factor(sub_merge$Compartments,levels=c("BS","RS","RE","VE","SE","LE","P"),
                             labels = c("BS", "RS","RE","VE","SE","LE","P"))

sub_merge$Phylum<-factor(sub_merge$Phylum,levels=c("Abditibacteriota", "Acidobacteriota", 
                                                   "Actinobacteriota","Alphaproteobacteria", 
                                                   "Bacteroidota","Chloroflexi","Deinococcota",
                                                   "Firmicutes","Gammaproteobacteria","Gemmatimonadota",
                                                   "Myxococcota","Nitrospirota","unclassified","Others"),
                         labels = c("Abditibacteriota", "Acidobacteriota", "Actinobacteriota","Alphaproteobacteria",
                                    "Bacteroidota","Chloroflexi","Deinococcota","Firmicutes","Gammaproteobacteria",
                                    "Gemmatimonadota","Myxococcota","Nitrospirota","unclassified","Others"))

phy.cols <- c("#FF6A6A","#FF8247","#FFE7BA","#87CEFA","#B0E0E6","#48D1CC","#5F9EA0","#66CDAA",
              "#458B00","#BCEE68","#FFF68F","#EEEE00","#FFFFE0","#8B8682") 

ggplot(sub_merge, aes(x = TreatmentID,y=`Relative abundance (%)`,fill=Phylum)) +
  geom_bar(stat='identity', position = "fill")+  
  labs(x="Treatment",y="Relative abundance")+
  facet_nested(Soiltype+Site~Compartments,drop=T,scale = "free",space="free")+
  scale_y_continuous(expand=c(0,0),labels=scales::percent)+
  theme_bw()+
  theme(axis.text.x = element_blank(),
        axis.ticks.x=element_blank(),
        axis.text.y = element_text(size = 8,color="black"),
        axis.title.y= element_text(size=12,color="black"),
        axis.title.x = element_text(size = 12),
        legend.title=element_text(size=12),
        legend.text=element_text(size=10),
        legend.position = "bottom",
        panel.spacing.x=unit(0,"lines"),
        panel.spacing.y=unit(0.5,"lines"))+
  scale_fill_manual(values=phy.cols) 
