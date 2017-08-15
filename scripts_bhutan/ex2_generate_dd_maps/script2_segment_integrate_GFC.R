####################################################################################
####### Object:  Segment and merge with existing classification               
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/07/23                                      
####################################################################################
library(foreign)
library(plyr)
library(rgeos)
library(rgdal)
library(raster)
library(ggplot2)

options(stringsAsFactors = F)

rootdir <- "/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/bhutan/gis_data_bhutan/"
gfcdir  <- paste0(rootdir,"gfc_2015/")
lsatdir <- "/media/dannunzio/hdd_remi/bhutan/time_series_image_dir/landsat/"

setwd(gfcdir)
start_time <- Sys.time()

####### Segmentation 2014
list <- list.files(lsatdir,glob2rx("*lsat_2014*.tif"))

for(file in list){
  system(sprintf("(echo 0; echo 0 ; echo 0)|oft-seg -region -ttest -automax %s %s",
               paste0(lsatdir,file),
               paste0(gfcdir,"/seg_",file)
               ))
}

####### Merge segments 2014
system(sprintf("gdal_merge.py -o %s -v -co COMPRESS=LZW %s",
               paste0(gfcdir,"tmp_segments_2014.tif"),
               paste0(gfcdir,"seg_*.tif")))

####### Clump segments 2014
system(sprintf("oft-clump -i %s -o %s -um %s",
               paste0(gfcdir,"tmp_segments_2014.tif"),
               paste0(gfcdir,"tmp_clump_2014.tif"),
               paste0(gfcdir,"tmp_segments_2014.tif"))) 

####### Create datamask
system(sprintf("oft-rasterize_attr.py -v  %s  -i   %s  -o %s -a %s",
               paste0("../boundaries_gaul/aoi_geo.shp"),
               paste0(gfcdir,"gfc_lossyear_bhutan.tif"),
               paste0(gfcdir,"data_mask.tif"),
               "id" 
))

####### Clip segments 2014
system(sprintf("oft-clip.pl %s %s %s",
               paste0(gfcdir,"data_mask.tif"),
               paste0(gfcdir,"tmp_clump_2014.tif"),
               paste0(gfcdir,"tmp_clip_clump_2014.tif")
               ))

#################### Mask out no data polygons
system(sprintf("gdal_calc.py -A %s -B %s --type=UInt32 --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfcdir,"tmp_clip_clump_2014.tif"),
               paste0(gfcdir,"data_mask.tif"),
               paste0(gfcdir,"clump_2014.tif"),
               "A*(B>0)"
))

####### Compute zonal stats for LOSSES
system(sprintf("oft-zonal_large_list.py -i %s -o %s -um %s",
               paste0(gfcdir,"gfc_lossyear_bhutan.tif"),
               paste0(gfcdir,"zonal_loss.txt"),
               paste0(gfcdir,"clump_2014.tif")
))

####### Compute zonal stats for treecover
system(sprintf("oft-zonal_large_list.py -i %s -o %s -um %s",
               paste0(gfcdir,"gfc_tc2000_bhutan.tif"),
               paste0(gfcdir,"zonal_tc2000.txt"),
               paste0(gfcdir,"clump_2014.tif")
))


####### Read zonal stats and rename columns
df_lossyr <- read.table(paste0(gfcdir,"zonal_loss.txt"))
df_tc2000 <- read.table(paste0(gfcdir,"zonal_tc2000.txt"))

names(df_lossyr)  <- c("clump_id","total","nodata",paste0("ly_",1:14))
names(df_tc2000)  <- c("clump_id","total","nodata",paste0("tc_",1:100))

head(df_lossyr)
head(df_tc2000)

df_tc2000$tc_gt_10 <- rowSums(df_tc2000[,14:103])
df_tc2000$tc_lt_10 <- rowSums(df_tc2000[,4:13])

summary(df_tc2000$total - df_tc2000$nodata - df_tc2000$tc_gt_10 - df_tc2000$tc_lt_10)

df <- cbind(df_lossyr,df_tc2000[,104:105])

df$loss <- rowSums(df[,paste0("ly_",1:14)])
df$tc_2014 <- df$tc_gt_10 - df$loss

df$new_class <- 0

df[df$tc_gt_10 <= 0.1 * (df$total - df$nodata),]$new_class <- 3
df[df$loss == 0 & df$tc_2014 > 0.1 * (df$total - df$nodata),]$new_class <- 4
df[df$tc_gt_10 > 0.1 * (df$total - df$nodata) & df$tc_2014 <= 0.1 * (df$total - df$nodata),]$new_class <- 11
df[df$loss > 0 & df$tc_2014 > 0.1 * (df$total - df$nodata),]$new_class  <- 12

table(df$new_class)
write.table(df[,c("clump_id","total","new_class")],
            paste0(gfcdir,"reclass.txt"),row.names = F,col.names = F)

####### Reclassify
system(sprintf("(echo %s; echo 1; echo 1; echo 3; echo 0) | oft-reclass  -oi %s  -um %s %s",
               paste0(gfcdir,"reclass.txt"),
               paste0(gfcdir,"tmp_reclass_clump_2014.tif"),
               paste0(gfcdir,"clump_2014.tif"),
               paste0(gfcdir,"clump_2014.tif")
               
))

####################  CREATE A PSEUDO COLOR TABLE
cols <- col2rgb(c("black","lightgrey","grey","darkgreen","red","orange","purple","blue"))

pct <- data.frame(cbind(c(0,1,3,4,11,12,21,22),
                        cols[1,],
                        cols[2,],
                        cols[3,]
)
)

write.table(pct,paste0(gfcdir,"/color_table.txt"),row.names = F,col.names = F,quote = F)

#################### CONVERT TO BYTE
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(gfcdir,"tmp_reclass_clump_2014.tif"),
               paste0(gfcdir,"tmp_byte_reclass_clump_2014.tif")
))
################################################################################
## Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(gfcdir,"/color_table.txt"),
               paste0(gfcdir,"tmp_byte_reclass_clump_2014.tif"),
               paste0(gfcdir,"tmp_pct_clump_2014.tif")
))


####### Compress
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(gfcdir,"tmp_pct_clump_2014.tif"),
               paste0(gfcdir,"DD_gfc_2014.tif")
))

####### Clean
system(sprintf("rm %s",
               paste0(gfcdir,"tmp*.tif")
               ))

####### Time
Sys.time()-start_time