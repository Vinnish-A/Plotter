library(tidyverse)
library(ggpubr)
library(ggalluvial)

sessionInfo()

df1 <- read_tsv("data.tsv")

# Set factor levels (ordered for display)
df1$RNA_specificity <- factor(df1$RNA_specificity,
  levels = c("Tissue enhanced", "Group enriched", "Tissue enriched"))

df1$Tissues <- factor(df1$Tissues, levels = c(
  "Kidney", "Urinary bladder", "Spleen", "Thymus", "Duodenum", "Stomach",
  "Salivary gland", "Pituitary gland", "Parathyroid gland", "Lung",
  "Spinal cord", "Hypothalamus", "Cerebellum", "Retina", "Liver",
  "Epididymis", "Ovary", "Breast", "Adipose tissue", "Small intestine",
  "Skeletal muscle", "Adrenal gland", "Cervix", "Endometrium",
  "Cerebral cortex", "Basal ganglia", "Choroid plexus", "Testis",
  "Fallopian tube"))

df1$Cell_types <- factor(df1$Cell_types, levels = c(
  "Not available", "Schwann cells", "Bipolar cells", "Sertoli cells",
  "Proximal tubular cells", "Granulosa cells", "Ductal cells",
  "Distal tubular cells", "AT2 cells", "Distal enterocytes",
  "Prostatic glandular cells", "Peritubular cells", "Ovarian stromal cells",
  "Enteroendocrine cells", "Leydig cells", "Plasma cells", "Granulocytes",
  "Dendritic cells", "Cytotrophoblasts", "Breast glandular cells",
  "Syncytiotrophoblasts", "Smooth muscle cells", "Monocytes",
  "Glandular and luminal cells", "Basal squamous epithelial cells",
  "Rod photoreceptor cells", "Oligodendrocytes", "Excitatory neurons",
  "Endometrial stromal cells", "Oocytes", "Proximal enterocytes",
  "Not detected", "Spermatocytes", "Oligodendrocyte precursor cells",
  "Mesothelial cells", "Inhibitory neurons", "Astrocytes",
  "Secretory cells", "Late spermatids", "Early spermatids", "Ciliated cells"))


HPA_all <- c(
  # RNA specificity
  "Tissue enriched"  = "#E41A1C",
  "Group enriched"   = "#FF9D00",
  "Tissue enhanced"  = "#984EA3",
  # Tissues (sorted by frequency)
  "Fallopian tube"   = "#F8BDD7",
  "Testis"           = "#95D4F5",
  "Choroid plexus"   = "#FFDD00",
  "Basal ganglia"    = "#FFDD00",
  "Cerebral cortex"  = "#FFDD00",
  "Endometrium"      = "#F8BDD7",
  "Cervix"           = "#F8BDD7",
  "Adrenal gland"    = "#7F6A9C",
  "Skeletal muscle"  = "#b38c6d",
  "Small intestine"  = "#1280c4",
  "Adipose tissue"   = "#A7DACD",
  "Breast"           = "#F8BDD7",
  "Ovary"            = "#F8BDD7",
  "Epididymis"       = "#95D4F5",
  "Liver"            = "#D1CBE5",
  "Retina"           = "#FFEF78",
  "Cerebellum"       = "#FFDD00",
  "Hypothalamus"     = "#FFDD00",
  "Spinal cord"      = "#FFDD00",
  "Lung"             = "#6AA692",
  "Parathyroid gland"= "#7F6A9C",
  "Pituitary gland"  = "#7F6A9C",
  "Salivary gland"   = "#FBDAD9",
  "Stomach"          = "#1280C4",
  "Duodenum"         = "#1280c4",
  "Thymus"           = "#de6c7d",
  "Spleen"           = "#de6c7d",
  "Urinary bladder"  = "#F9A266",
  "Kidney"           = "#F9A266",
  # Cell types (sorted by frequency)
  "Ciliated cells"                  = "#404785",
  "Early spermatids"                = "#95D4F5",
  "Late spermatids"                 = "#95D4F5",
  "Secretory cells"                 = "#404785",
  "Astrocytes"                      = "#FFDD00",
  "Inhibitory neurons"              = "#FFDD00",
  "Mesothelial cells"               = "#5191b2",
  "Oligodendrocyte precursor cells" = "#FFDD00",
  "Spermatocytes"                   = "#95D4F5",
  "Not detected"                    = "grey",
  "Proximal enterocytes"            = "#404785",
  "Oocytes"                         = "#95D4F5",
  "Endometrial stromal cells"       = "#F8BDD7",
  "Excitatory neurons"              = "#FFDD00",
  "Oligodendrocytes"                = "#FFDD00",
  "Rod photoreceptor cells"         = "#ffdd00",
  "Basal squamous epithelial cells" = "#FCCAB3",
  "Glandular and luminal cells"     = "#3f4784",
  "Monocytes"                       = "#b30000",
  "Smooth muscle cells"             = "#b38c6d",
  "Syncytiotrophoblasts"            = "#f8bdd7",
  "Breast glandular cells"          = "#f8bdd7",
  "Cytotrophoblasts"                = "#f8bdd7",
  "Dendritic cells"                 = "#b30000",
  "Granulocytes"                    = "#b30000",
  "Plasma cells"                    = "#b30000",
  "Leydig cells"                    = "#7f6a9c",
  "Enteroendocrine cells"           = "#7f6a9c",
  "Ovarian stromal cells"           = "#66bd63",
  "Peritubular cells"               = "#66bd63",
  "Prostatic glandular cells"       = "#404785",
  "Distal enterocytes"              = "#404785",
  "AT2 cells"                       = "#5191b2",
  "Distal tubular cells"            = "#5191b2",
  "Ductal cells"                    = "#5191b2",
  "Granulosa cells"                 = "#5191b2",
  "Proximal tubular cells"          = "#5191b2",
  "Sertoli cells"                   = "#5191b2",
  "Bipolar cells"                   = "#ffdd00",
  "Schwann cells"                   = "#dfbd69",
  "Not available"                   = "grey")

label_keep <- c(
  "Tissue enhanced", "Group enriched", "Tissue enriched",
  "Choroid plexus", "Testis", "Fallopian tube",
  "Secretory cells", "Late spermatids", "Early spermatids", "Ciliated cells"
)

ggplot(df1, aes(axis1 = RNA_specificity, axis2 = Tissues, axis3 = Cell_types)) +
  geom_alluvium(aes(fill = Tissues), curve_type = "sigmoid", width = 0.4, alpha = 0.8) +
  geom_stratum(aes(fill = after_stat(stratum)), color = "grey99", width = 0.45) +
  geom_text(stat = "stratum",aes(label = ifelse(
      after_stat(stratum) %in% label_keep,
      ifelse(
        after_stat(x) == 1,
        paste0(after_stat(stratum), "\n", after_stat(count), " genes"),
        as.character(after_stat(stratum))),"")),size = 3.5,color="white") +
  scale_fill_manual(values = HPA_all) +
  scale_x_continuous(breaks = 1:3,labels = c("RNA specificity", "Tissues", "Cell types"),
                     position = "top") +
  scale_y_continuous(expand = c(0,0)) +
  theme(legend.position = "none",
        axis.text.y=element_blank(),
        plot.background = element_blank(),
        panel.background = element_blank(),
        axis.ticks = element_blank(),
        axis.text.x.top=element_text(color="black",size=11,face="bold"))


