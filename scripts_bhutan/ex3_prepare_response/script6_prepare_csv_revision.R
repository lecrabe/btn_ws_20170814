####################################################################################################
####################################################################################################
## Prepare data for time series clipping
## Contact remi.dannunzio@fao.org
## 2017/05/19 -- Cambodia
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
setwd("/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/cambodia/workshop_2017/results/")

## Read the datafile and setup the correct names for the variables
pts_results <- read.csv("remilinux_collectedData_earthaa_cambodia_CE_2017-05-18_on_180517_115425_CSV.csv")
pts_origin  <- read.csv("cambodia_CE_2017-05-18.csv")

table(pts_results$map_class,pts_results$ref_class)

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