####################################################################################################
####################################################################################################
## Prepare data for time series clipping
## Contact remi.dannunzio@fao.org
## 2017/09/18 --  Bhutan
####################################################################################################
####################################################################################################
options(stringsAsFactors=FALSE)

library(Hmisc)
library(sp)
library(rgdal)
library(raster)
library(plyr)
library(foreign)

#######################################################################
##############################     SETUP YOUR DATA 
#######################################################################

## Set your working directory
setwd(#"/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/bhutan/aa_change_951016/
"/home/dannunzio/AA_bhutan_work/")

list <- list.files(".",pattern=glob2rx("*collectedData_*2004_2009*.csv"))
for(i in 1:length(list)){
  print(i)
  tmp <- read.csv(list[i])
  print(ncol(tmp))
  if(i ==1){df <- tmp}else{
  df <- rbind(df,tmp)
  }
}

df1 <- read.csv("ArunRai_collectedData_earthsae_CE_2017-09-11_2004_2009_on_130917_095021_CSV.csv")
df2 <- read.csv("Phuntsho_collectedData_earthsae_CE_2017-09-11_2004_2009_on_140917_141112_CSV.csv")
df3 <- read.csv("DawaZangpo_collectedData_earthsae_CE_2017-09-11_2004_2009_on_130917_172456_CSV.csv")

df2 <- df2[!(df2$id %in% df1$id),]
df2 <- df2[!(df2$id %in% df3$id),]

df <- rbind(df1,df2,df3)

table(df$ref_class_label,df$map_class_label)
table(df$operator)

df_2004_2009 <- df

df1 <- read.csv("ArunRai_collectedData_earthsae_CE_2017-09-11_2009_2014_on_140917_122353_CSV.csv")
df2 <- read.csv("Phuntsho_collectedData_earthsae_CE_2017-09-11_2009_2014_on_140917_141008_CSV.csv")
df3 <- read.csv("DawaZangpo_collectedData_earthsae_CE_2017-09-11_2009_2014_on_140917_140304_CSV.csv")


list <- list.files(".",pattern=glob2rx("*collectedData_*2009_2014*.csv"))
for(i in 1:length(list)){
  print(i)
  tmp <- read.csv(list[i])
  print(ncol(tmp))
  if(i ==1){df <- tmp}else{
    df <- rbind(df,tmp)
  }
}

table(df$ref_class_label)
df <- df[df$ref_class_label != "",]
df_2009_2014 <- df

write.csv(df_2004_2009,"res_all_2004_2009.csv",row.names = F)
write.csv(df_2009_2014,"res_all_2009_2014.csv",row.names = F)

## Read the datafile and setup the correct names for the variables
pts_results <- read.csv("res_all_2004_2009.csv")
pts_origin  <- read.csv("CEP/CE_2017-09-11_2004_2009.csv")

table(pts_results$map_class,pts_results$ref_class)
table(pts_results$map_class_label,pts_results$ref_class_label)

check_phtunsho <- pts_results[pts_results$ref_class == 2 & 
                                pts_results$operator == "Phuntsho" & 
                                pts_results$map_class == 3,]
check_phtunsho$id

out <- pts_origin[
  pts_origin$id %in% pts_results[
    (pts_results$ref_class == 2 & pts_results$map_class == 1)
    |
    (pts_results$ref_class == 3 & pts_results$map_class == 2)
    ,
    ]$id,
  ]

## Export as csv file
write.csv(out,paste("check_20170519.csv",sep=""),row.names=F)

## HELLO!!!