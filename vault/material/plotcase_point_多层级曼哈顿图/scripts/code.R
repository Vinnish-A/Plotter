install.packages("CMplot")
library(CMplot)
library(tidyverse)
data(pig60K)

sessionInfo()

pig60K <- pig60K %>% select(1,2,3,4,5)

CMplot(pig60K,type="p",plot.type="c",chr.labels=paste("Chr",c(1:18,"X","Y"),sep=""),
       r=0.5,cir.axis=TRUE,
       outward=FALSE,cir.axis.col="black",cir.chr.h=1.3,chr.den.col="black")

# 保存为pdf文件
CMplot(pig60K,type="p",plot.type="c",chr.labels=paste("Chr",c(1:18,"X","Y"),sep=""),
       r=0.5,cir.axis=TRUE,
       outward=FALSE,cir.axis.col="black",cir.chr.h=1.3,chr.den.col="black",file="pdf",
       file.name="",dpi=300,file.output=TRUE,verbose=TRUE,width=10,height=10)