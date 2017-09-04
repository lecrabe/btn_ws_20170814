####################################################################################
####### Object:  Segment and merge with existing classification               
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/09/04                                     
####################################################################################
library(foreign)
library(plyr)
library(rgeos)
library(rgdal)
library(raster)
library(ggplot2)

options(stringsAsFactors = F)

rootdir <- "~/btn_ws_20170814/gis_data_bhutan/"
setwd(rootdir)
rootdir <- paste0(getwd(),"/")

gfcdir  <- paste0(rootdir,"gfc_2015/")
segdir  <- paste0(rootdir,"segments_FREL/")
dir.create(segdir)
setwd(segdir)

system("wget https://www.dropbox.com/s/ae6b5cxcbejb85b/segments_FREL.zip?dl=0")
system("unzip segments_FREL.zip?dl=0")

