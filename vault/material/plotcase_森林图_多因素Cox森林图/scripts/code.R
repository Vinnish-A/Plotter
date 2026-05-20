library(readxl)    
library(tidyverse)  
library(survival)  
library(survminer) 

sessionInfo()

df <- read_excel("43018_2025_1072_MOESM3_ESM.xlsx",sheet = 3,skip = 1)
# 变量重命名与临床变量整理
df <- df %>% mutate(
  # 基本人口学变量
  Sex = d_pt_sex,                 # 性别
  Age = d_dx_amm_age,             # 诊断年龄
  # 治疗相关变量
  Transplant = d_amm_tx_asct_1st, # 是否接受移植
  # 生存结局变量
  PFS = censpfs,                  # PFS结局（是否发生事件）
  PFS.time = ttcpfs,              # PFS随访时间
  OS = censos,                    # OS结局
  OS.time = ttcos,                # OS随访时间
  # 诱导治疗方案重新分类（合并类别）
  Treatment = case_when(
    d_tx_induction_cat == "chemo_imid_pi_steroid" ~ "imid_pi_steroid",
    d_tx_induction_cat == "chemo_pi_steroid" ~ "pi_steroid",
    TRUE ~ d_tx_induction_cat),
  # 风险分层（去除无法计算数据）
  risk = case_when(
    davies_based_risk3 %in% c("no_risk_data", "not_calculable") ~ NA_character_,
    TRUE ~ as.character(davies_based_risk3)),
  # ECOG体能状态分组
  ECOG = case_when(
    d_dx_amm_ecog %in% c("3", "4") ~ ">=3",
    TRUE ~ as.character(d_dx_amm_ecog)),
  # 种族重新分组
  Race = case_when(
    d_pt_race_1 %in% c("asian_nos", "unknown") ~ "others/unknown",
    d_pt_race_1 %in% c("black_african_american") ~ "black",
    TRUE ~ as.character(d_pt_race_1)),
  # ISS分期标准化
  ISS_stage = case_when(
    d_dx_amm_iss_stage %in% c("1") ~ "stage I",
    d_dx_amm_iss_stage %in% c("2") ~ "stage II",
    d_dx_amm_iss_stage %in% c("3") ~ "stage III",
    TRUE ~ as.character(d_dx_amm_iss_stage))) %>%
  
# 决定 Cox 模型 reference level
mutate(Treatment = factor(
  Treatment,levels = c("pi_steroid","imid_pi_steroid","imid_steroid")),
  risk = factor(risk,levels = c("standard_risk", "high_risk")),
  ECOG = factor(ECOG,levels = c("0", "1", "2", ">=3")),
  Race = factor(Race,levels = c("white", "black", "others/unknown")),
  ISS_stage = factor(ISS_stage,levels = c("stage I", "stage II", "stage III"))) %>%
  # 确保时间变量为数值型
  mutate(PFS.time = as.numeric(PFS.time))
# 查看关键变量
df %>% select(Transplant, Treatment, risk, ECOG, ISS_stage) %>% head()

# 构建 Cox 回归模型公式
formula <- as.formula(
  paste("Surv(PFS.time, PFS) ~",
        "Age + Sex + Race + ISS_stage +
         Transplant + Treatment + risk + ECOG"))

# 拟合 Cox 比例风险模型
model <- coxph(formula, data = as.data.frame(df))
# 绘制森林图
ggforest(model,
  data = as.data.frame(df),
  main = 'Hazard ratio of progression free survival', # 图标题
  cpositions = c(0.0, 0.25, 0.45),  # 列布局位置
  fontsize = 0.8,                    # 字体大小
  refLabel = '1.00',                 # 参考值标签
  noDigits = 2)                      # HR保留小数位

