library(tidyverse)
library(magrittr)
library(MASS)
library(relaimpo)
library(psych)
library(reshape2)
library(aplot)

sessionInfo()

env <- read_tsv("env.tsv") %>% column_to_rownames(var = "sample")
spe <- read_tsv("spe.tsv") %>% column_to_rownames(var = "sample")


analyze_species <- function(spename) {
  df <- cbind(env, spe[[spename]]) %>% as.data.frame()
  colnames(df)[ncol(df)] <- "spe"
  # 原始回归
  fit <- lm(spe ~ ., data = df)
  # 使用 stepAIC 精简模型
  fit_simple <- stepAIC(fit, direction = "backward", trace = FALSE)
  lm_stat <- summary(fit_simple)
  # 提取 R2
  radj <- lm_stat$adj.r.squared
  # 安全提取 p 值（防止无自变量时报错）
  if (!is.null(lm_stat$fstatistic)) {
    F <- lm_stat$fstatistic
    pvalue <- pf(F[1], F[2], F[3], lower.tail = FALSE)
  } else {
    pvalue <- NA
  }
  # 方差分解，如果模型有自变量才计算
  env_imp <- NULL
  if (length(attr(terms(fit_simple), "term.labels")) > 0) {
    crf <- calc.relimp(fit_simple, rela = FALSE)$lmg %>%
      as.data.frame() %>%
      rownames_to_column("env") %>%
      rename(importance = 2) %>%
      mutate(spe = spename)
    env_imp <- crf
  }
  # 返回结果
  return(list(
    env_imp = env_imp,
    lm_stat = tibble(id = spename, radj = radj, pvalue = pvalue)
  ))
}

results <- map(colnames(spe),analyze_species)

envdata <- map_dfr(results, "env_imp")

lm_result <- map_dfr(results, "lm_stat") %>%
  mutate(
    p_signif = symnum(pvalue,
      corr = FALSE,na = FALSE,
      cutpoints = c(0, 0.001, 0.01, 0.05, 0.1, 1),
      symbols = c("***", "**", "*", "", " ")))

spearman <- corr.test(env,spe,method = 'spearman', adjust = 'none')


p1 <- melt(spearman$r) %>%
  mutate(pvalue=melt(spearman$p.adj)[,3],
         p_signif=symnum(pvalue, corr = FALSE, na = FALSE,  
                         cutpoints = c(0, 0.001, 0.01, 0.05,1),
                         symbols = c("***", "**", "*", ""))) %>% 
  set_colnames(c("env","spe","r","p","p_signif")) %>% 
  ggplot(.,aes(spe,env))+
  geom_tile(aes(fill=r))+
  geom_text(aes(label=p_signif),
            size=3,color="white",hjust=0.5,vjust=0.7)+
  geom_point(data = envdata,
             aes(x = spe,y = env,
                 size = importance*100),shape=21) +
  scale_size_continuous(range = c(0,8)) +
  labs(x = NULL,y = NULL,color=NULL,fill=NULL,
       size = 'Importance (%)')+
  scale_color_gradientn(
    colours = rev(RColorBrewer::brewer.pal(11,"RdBu")))+
  scale_fill_gradientn(
    colours = rev(RColorBrewer::brewer.pal(11,"RdBu")))+
  scale_x_discrete(expand=c(0,0))+
  scale_y_discrete(expand=c(0,0),position = 'left') +
  theme_test() +
  theme(axis.text.x=element_text(
    angle =50,hjust =1,vjust =1,color="black",size = 10),
        axis.text.y=element_text(color="black",size =10),
        axis.ticks= element_blank(),
        legend.background = element_blank(),
        legend.key = element_blank())

p2 <- ggplot(lm_result,aes(id,radj*100,label=p_signif))+
  geom_col(fill = '#4882B2',width = 0.7)+
  geom_text(aes(label=p_signif),size=5,
            color="black",hjust=0.5,vjust=0.5)+
  labs(title = 'Explained variation (%)',
       x=NULL,y=NULL)+
  theme(panel.grid = element_blank(),
        panel.background = element_blank(), 
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        title=element_text(size=8,color="black"),
        axis.text.y = element_text(color = 'black'), 
        axis.line = element_line(color = 'black'),
        axis.ticks = element_line(color = 'black')) +
  scale_y_continuous(expand = c(0,0.5),
                     limits = c(0,100))

p1 %>% insert_top(p2,height = 0.2)

