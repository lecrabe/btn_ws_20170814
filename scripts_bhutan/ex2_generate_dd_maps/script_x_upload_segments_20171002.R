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

###### Set directories
rootdir <- "~/btn_ws_20170814/gis_data_bhutan/"
dir.create(rootdir,recursive = T)
setwd(rootdir)
rootdir <- paste0(getwd(),"/")

gfcdir  <- paste0(rootdir,"gfc_2015/")
segdir  <- paste0(rootdir,"segments_FREL/")
dir.create(segdir)
setwd(segdir)


######### G_DRIVE SOLUTION THROUGH
######### http://olivermarshall.net/how-to-upload-a-file-to-google-drive-from-the-command-line/
  
# system("download_url = \"https://drive.google.com/uc?authuser\u003d0\u0026id\u003d0B48Ol_Tb6ewSX1RVcEZCRm9lWGM\u0026export\u003ddownload\" ") 
# # -O essayons https://googledrive.com/host/0B48Ol_Tb6ewSX1RVcEZCRm9lWGM")
# system("curl -L -o retest https://drive.google.com/uc?id=0B48Ol_Tb6ewSX1RVcEZCRm9lWGM")
# 
# system("wget u'https://drive.google.com/uc?authuser=0&id=0B48Ol_Tb6ewSX1RVcEZCRm9lWGM&export=download'")
# system("wget -O output https://drive.google.com/uc?authuser\u003d0\u0026id\u003d0B48Ol_Tb6ewSX1RVcEZCRm9lWGM\u0026export\u003ddownload")

system(sprintf("echo 4/SGn-wOSw1u0Pt2kW3Sctd_4nyrYX0ZMsn2YcJWvYejc | gdrive download 0B48Ol_Tb6ewSX1RVcEZCRm9lWGM --force"))

system("unzip segments_FREL.zip?dl=0")

###### Create unique POLYGON ID
#segs       <- readOGR(shapename,base)
dbf <- read.dbf(paste0(segdir,base,".dbf"))
dbf$ID    <- row(dbf)[,1]

write.dbf(dbf,paste0(segdir,base,".dbf"))

summary(dbf)
hist(dbf$areas)

###### Create unique ID for boundaries
# dbf <- read.dbf(paste0("boundaries_bhutan/bhutan.dbf"))
# dbf$id <- row(dbf)[,1]
# write.dbf(dbf,paste0("boundaries_bhutan/bhutan.dbf"))
