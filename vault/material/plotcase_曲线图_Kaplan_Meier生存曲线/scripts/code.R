library(tidyverse)
library(survival)
library(survminer)

sessionInfo()

# 读取临床信息数据
patient_metadata <- read.csv("./patient_metadata.csv")

# 构建总生存（OS）的生存对象
# time  ：生存时间（单位：月）
# event ：结局事件（通常 1 = 死亡，0 = 删失）
clear_cell_data_OS <- Surv(time = patient_metadata$OS_mo, 
                           event = patient_metadata$OS_stauts)

# 按 PPP2R1A 突变状态对生存数据进行分组拟合
# 得到每个分组对应的 Kaplan–Meier 生存曲线
clear_cell_data_OS_fit <- survfit(clear_cell_data_OS ~ PPP2R1A_mutation, 
                                  data = patient_metadata)

# 绘制 Kaplan–Meier 生存曲线及风险表
ggsurvplot(clear_cell_data_OS_fit,
           data = patient_metadata,                  
           risk.table = TRUE,    # 显示下方的风险表（Number at risk）
           legend.labs = levels(patient_metadata$PPP2R1A_mutation), 
           # 图例标签，来自突变分组的因子水平
           palette = c("#83b2d3", "#fbb463"),          
           break.x.by = 12,           # X 轴按 12 个月间隔显示刻度
           risk.table.y.text.col = TRUE, # 风险表中分组文字按对应颜色显示
           risk.table.y.text = FALSE, # 隐藏风险表左侧的分组文字
           ggtheme = theme_classic())

