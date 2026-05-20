library(tidyverse)
library(ggtree)
library(magrittr)
#install.packages("legendry")
library(legendry)
library(aplot)
library(ape)
library(treeio)
library(phytools)

sessionInfo()

tree_f  = "Fig2a.tree"
meta_f  = "Fig2a.csv"
tr <- read.tree(tree_f)
meta_df <- read_csv(meta_f, show_col_types = FALSE) %>%
  filter(biosample_id %in% tr$tip.label) %>%
  as.data.frame()
rownames(meta_df) <- meta_df$biosample_id

meta_df <- meta_df[, c("niche", "country", "npmA_presence", "Composite_Tn", "ICE_MGE_type")]
meta_df[] <- lapply(meta_df, as.character)

p <- ggtree(midpoint.root(tr), layout = "rectangular")

df <- meta_df %>% rownames_to_column(var="id") %>% 
  pivot_longer(-id) %>% drop_na() %>% 
  mutate(name=case_when(name == "niche" ~ "1.niche",
                        name == "country" ~ "2.country",
                        name == "npmA_presence" ~ "3.npmA variant",
                        name == "Composite_Tn" ~ "4.Tn7734",
                        name == "ICE_MGE_type" ~ "5.ICE variant")) %>% 
  mutate(value=case_when(value == "yes" ~ "Tn7734",
                         value == "ICE2" ~ "Other ICE",
                         value == "ICE_v5" ~ "Other ICE",
                         TRUE ~ value)) %>% 
  set_colnames(c("id","group","name"))

dff <- df %>% distinct(group,name) %>% 
  mutate(group = factor(group, levels = unique(df$group)))

lut <- key_group_lut(dff$name,dff$group)
df$group <- factor(df$group,levels = unique(df$group))

heat <- df %>% ggplot(.,aes(group,id,fill=paste(group,name))) +
  geom_tile(aes(fill=name)) +
  guides(fill = guide_legend_group(key = lut,title=NULL))+
  scale_x_discrete(expand = c(0,0)) +
  geom_vline(xintercept = c(1.5,2.5,3.5,4.5),linewidth=0.3)  +
  scale_fill_manual(
    values = c("Australia"= "#F4C7DE","Austria"= "#9AC4F6",
               "Belgium"= "#B1D1A2","Canada" = "#C1C1C1",
               "China"= "#F9D275","France"="#2B3C70",
               "Germany"= "#FAE664","Hungary"= "#A9A9A9",
               "Indonesia"  = "#C1DAB4","Iran"= "#4D704D",
               "Ireland"  = "#75B9D2","Italy"= "#A1D8C8",
               "Netherlands"= "#F79533","Poland"= "#F86BA1","Portugal"= "#D6C6CA",
               "Spain"= "#F7A98A","Switzerland"= "#C3E27F",
               "United Kingdom"= "#B6C5DA", "United States" = "#730021","Human"= "#5CA4E6",
               "Livestock"= "#E84A4A","Companion Animal" = "#5B331B",
               "Environment"="#34732D","Food"="#A259D0","npmA1"="#F97A1E","npmA2" = "#2A2E82",
               "ICE_v1" = "#B0DBF1","ICE_v2" = "#A0E0E0","ICE_v3" = "#E6B7DA",
               "ICE_v4" = "#F97979","Other ICE" = "#1A1A1A","Tn7734"= "#F5BE35",
               "one_copy_IS30"="#EBD889")) +
  theme_test()+
  theme(axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        axis.title = element_blank(),
        axis.text.x=element_text(angle=90,color="black",vjust=0.5,hjust=1),
        legend.key.spacing.y = unit(0,"cm"),
        legend.key.height = unit(0.4,"cm"),
        legend.key.width = unit(0.4,"cm"))

heat %>% insert_left(p,width = c(1,0.4))

