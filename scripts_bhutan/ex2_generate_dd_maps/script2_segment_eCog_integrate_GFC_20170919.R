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
#rootdir <- "/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/bhutan/gis_data_bhutan/"
rootdir <- "~/btn_ws_20170814/gis_data_bhutan/"
setwd(rootdir)
rootdir <- paste0(getwd(),"/")

gfcdir  <- paste0(rootdir,"gfc_2015/")
segdir  <- paste0(rootdir,"segments_FREL/")

start_time <- Sys.time()

####### Read shapefile of segmentation from eCognition
shapename <- paste0(segdir,"ScalePara2_shape0.1_compact0.2.shp")
base <- substr(basename(shapename),1,nchar(basename(shapename))-4)

# ####### Compute above 10% threshold for TC
# system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                paste0(gfcdir,"gfc_tc2000_bhutan.tif"),
#                paste0(gfcdir,"gfc_tc2000_gt10_bhutan.tif"),
#                "(A>10)*A"
# ))
# 
# ####### Compute above 10% threshold for LOSSYEAR
# system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                paste0(gfcdir,"gfc_lossyear_bhutan.tif"),
#                paste0(gfcdir,"gfc_tc2000_gt10_bhutan.tif"),
#                paste0(gfcdir,"gfc_lossyear_gt10_bhutan.tif"),
#                "(B>10)*A"
# ))             
# 
# ####### Reproject in DRUK (EPSG:5266)
# list <- list.files(paste0(gfcdir),pattern = glob2rx("gfc*.tif"))
# list <- c("gfc_gain_bhutan.tif","gfc_lossyear_gt10_bhutan.tif","gfc_tc2000_gt10_bhutan.tif")
# 
# for(layer in list ){
#   print(layer)
#   system(sprintf("gdalwarp -t_srs EPSG:5266 -co COMPRESS=LZW %s %s",
#                  paste0(gfcdir,layer),
#                  paste0(gfcdir,"druk_",layer)
#   ))
# }
# 
# ####### Rasterize segments
# e <- extent(raster(paste0(gfcdir,"druk_gfc_lossyear_gt10_bhutan.tif")))
# r <- res(raster(paste0(gfcdir,"druk_gfc_lossyear_gt10_bhutan.tif")))
# 
# system(sprintf("gdal_rasterize -a %s -l %s -ot UInt32 -te %s %s %s %s -tr %s %s -co \"COMPRESS=LZW\" %s %s",
#                "ID" ,
#                base,
#                e@xmin,
#                e@ymin,
#                e@xmax,
#                e@ymax,
#                r[1],
#                r[1],
#                shapename,
#                paste0(segdir,"segments.tif")
#                ))
# 
# 
# ###### Create datamask
# system(sprintf("gdal_rasterize -a %s -l %s -te %s %s %s %s -tr %s %s -co \"COMPRESS=LZW\" %s %s",
#                "id" ,
#                "bhutan",
#                e@xmin,
#                e@ymin,
#                e@xmax,
#                e@ymax,
#                r[1],
#                r[1],
#                paste0("boundaries_bhutan/bhutan.shp"),
#                paste0(gfcdir,"data_mask.tif")
# ))
# 
# 
# #################### Mask out no data polygons
# system(sprintf("gdal_calc.py -A %s -B %s --type=UInt32 --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                paste0(segdir,"segments.tif"),
#                paste0(gfcdir,"data_mask.tif"),
#                paste0(segdir,"mask_segments.tif"),
#                "A*(B>0)"
# ))
# 
# 
# ####### Compute zonal stats for LOSSES
# system(sprintf("oft-his -i %s -o %s -um %s -maxval %s",
#                paste0(gfcdir,"druk_gfc_lossyear_gt10_bhutan.tif"),
#                paste0(gfcdir,"tmp_zonal_loss.txt"),
#                paste0(segdir,"mask_segments.tif"),
#                14
# ))
# 
# ####### Compute zonal stats for GAINS
# system(sprintf("oft-his -i %s -o %s -um %s -maxval %s",
#                paste0(gfcdir,"druk_gfc_gain_bhutan.tif"),
#                paste0(gfcdir,"tmp_zonal_gain.txt"),
#                paste0(segdir,"mask_segments.tif"),
#                1
#                ))
# 
# ####### Compute zonal stats for TREECOVER
# system(sprintf("oft-his -i %s -o %s -um %s -maxval %s",
#                paste0(gfcdir,"druk_gfc_tc2000_gt10_bhutan.tif"),
#                paste0(gfcdir,"tmp_zonal_tc2000.txt"),
#                paste0(segdir,"mask_segments.tif"),
#                100
# ))


####### Read zonal stats and rename columns
df_lossyr <- read.table(paste0(gfcdir,"tmp_zonal_loss.txt"))
df_tc2000 <- read.table(paste0(gfcdir,"tmp_zonal_tc2000.txt"))
df_gain   <- read.table(paste0(gfcdir,"tmp_zonal_gain.txt"))

names(df_lossyr)  <- c("clump_id","total","nodata",paste0("ly_",1:14))
names(df_tc2000)  <- c("clump_id","total","nodata",paste0("tc_",1:100))
names(df_gain)    <- c("clump_id","total","nodata","gain")

head(df_lossyr)
head(df_tc2000)


quantile(df$total)
####### Bind loss and Tree cover in the same data frame
df <- cbind(df_lossyr,df_tc2000[,4:103],df_gain[,"gain"])
names(df)[ncol(df)] <- "gain"
df$tc2000   <- rowSums(df[,paste0("tc_",1:100)])
df$tc2001   <- df$tc2000 - df$ly_1 + df$gain/14
df$tc2002   <- df$tc2001 - df$ly_2 + df$gain/14
df$tc2003   <- df$tc2002 - df$ly_3 + df$gain/14
df$tc2004   <- df$tc2003 - df$ly_4 + df$gain/14
df$tc2005   <- df$tc2004 - df$ly_5 + df$gain/14
df$tc2006   <- df$tc2005 - df$ly_6 + df$gain/14
df$tc2007   <- df$tc2006 - df$ly_7 + df$gain/14
df$tc2008   <- df$tc2007 - df$ly_8 + df$gain/14
df$tc2009   <- df$tc2008 - df$ly_9 + df$gain/14
df$tc2010   <- df$tc2009 - df$ly_10 + df$gain/14
df$tc2011   <- df$tc2010 - df$ly_11 + df$gain/14
df$tc2012   <- df$tc2011 - df$ly_12 + df$gain/14
df$tc2013   <- df$tc2012 - df$ly_13 + df$gain/14
df$tc2014   <- df$tc2013 - df$ly_14 + df$gain/14

summary(df$tc2014-df$tc2000+rowSums(df[,paste0("ly_",1:14)])-df$gain)

################# New class
# Forest 11 (TC < 40)
# Forest 12 (40 < TC < 70)
# Forest 13 (TC > 70)
# Non Forest 2
# Deforestation (F -> NF) 3 
# Degradation  (>40 -> <40) 41
# Degradation  (>70 -> >40) 42
# Degradation  (>70 -> <40) 43

# Gain (TC 14 > TC 00) 5

################## Change between 2004 and 2009
df$chge_0409 <- 2

df[df$tc2004 >  0.1*df$total & df$tc2009 > 0.1*df$total,]$chge_0409   <- 11
df[df$tc2004 >  0.4*df$total & df$tc2009 > 0.4*df$total,]$chge_0409   <- 12
df[df$tc2004 >  0.7*df$total & df$tc2009 > 0.7*df$total,]$chge_0409   <- 13

df[df$tc2009 <= 0.1*df$total & df$tc2004 <= 0.1*df$total,]$chge_0409  <- 2

df[df$tc2004 >  0.4*df$total & df$tc2009 <= 0.4*df$total & df$tc2009 > 0.1*df$total,]$chge_0409 <- 41
df[df$tc2004 >  0.7*df$total & df$tc2009 <= 0.4*df$total & df$tc2009 > 0.1*df$total,]$chge_0409 <- 43
df[df$tc2004 >  0.7*df$total & df$tc2009 <= 0.7*df$total & df$tc2009 > 0.4*df$total,]$chge_0409 <- 42

df[df$tc2004 >  0.1*df$total & df$tc2009 <= 0.1*df$total & (df$tc2004 - df$tc2009) > 0.1*df$total,]$chge_0409 <- 3

df[(df$tc2009 - df$tc2004) > 5 & df$tc2009 > 0.1*df$total,]$chge_0409    <- 5

table(df$chge_0409)

################## Change between 2009 and 2014
df$chge_0914 <- 2

df[df$tc2009 >  0.1*df$total & df$tc2014 > 0.1*df$total,]$chge_0914   <- 11
df[df$tc2009 >  0.4*df$total & df$tc2014 > 0.4*df$total,]$chge_0914   <- 12
df[df$tc2009 >  0.7*df$total & df$tc2014 > 0.7*df$total,]$chge_0914   <- 13

df[df$tc2014 <= 0.1*df$total & df$tc2009 <= 0.1*df$total,]$chge_0914  <- 2

df[df$tc2009 >  0.4*df$total & df$tc2014 <= 0.4*df$total & df$tc2014 > 0.1*df$total,]$chge_0914 <- 41
df[df$tc2009 >  0.7*df$total & df$tc2014 <= 0.4*df$total & df$tc2014 > 0.1*df$total,]$chge_0914 <- 43
df[df$tc2009 >  0.7*df$total & df$tc2014 <= 0.7*df$total & df$tc2014 > 0.4*df$total,]$chge_0914 <- 42

df[df$tc2009 >  0.1*df$total & df$tc2014 <= 0.1*df$total & (df$tc2009 - df$tc2014) > 0.1*df$total,]$chge_0914 <- 3

df[(df$tc2014 - df$tc2009) > 5 & df$tc2014 > 0.1*df$total & df$chge_0409 != 5 ,]$chge_0914    <- 5

table(df$chge_0914)


table(df$total)
write.table(df[,c("clump_id","total","chge_0409","chge_0914")],
            paste0(gfcdir,"reclass.txt"),row.names = F,col.names = F)

####### Reclassify for 2004-2009
system(sprintf("(echo %s; echo 1; echo 1; echo 3; echo 0) | oft-reclass  -oi %s  -um %s %s",
               paste0(gfcdir,"reclass.txt"),
               paste0(gfcdir,"tmp_reclass_segments.tif"),
               paste0(segdir,"mask_segments.tif"),
               paste0(segdir,"mask_segments.tif")
))

####################  CREATE A PSEUDO COLOR TABLE
cols <- col2rgb(c("black","lightgrey","red","blue","lightgreen","green","darkgreen","orange","orange1","yellow"))

pct <- data.frame(cbind(c(0,2,3,5,11,12,13,41,42,43),
                        cols[1,],
                        cols[2,],
                        cols[3,]
)
)

write.table(pct,paste0(gfcdir,"/color_table.txt"),row.names = F,col.names = F,quote = F)

#################### CONVERT TO BYTE
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(gfcdir,"tmp_reclass_segments.tif"),
               paste0(gfcdir,"tmp_byte_reclass_segments.tif")
))

################################################################################
## Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(gfcdir,"/color_table.txt"),
               paste0(gfcdir,"tmp_byte_reclass_segments.tif"),
               paste0(gfcdir,"tmp_pct_byte_reclass_segments.tif")
))

#################### Compress
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(gfcdir,"tmp_pct_byte_reclass_segments.tif"),
               paste0(gfcdir,"DD_2004_2009_druk_20170919.tif")
))


####### Reclassify for 2009-2014
system(sprintf("(echo %s; echo 1; echo 1; echo 4; echo 0) | oft-reclass  -oi %s  -um %s %s",
               paste0(gfcdir,"reclass.txt"),
               paste0(gfcdir,"tmp_reclass_segments.tif"),
               paste0(segdir,"mask_segments.tif"),
               paste0(segdir,"mask_segments.tif")
))

####################  CREATE A PSEUDO COLOR TABLE
cols <- col2rgb(c("black","lightgrey","red","blue","lightgreen","green","darkgreen","orange","orange1","yellow"))

pct <- data.frame(cbind(c(0,2,3,5,11,12,13,41,42,43),
                        cols[1,],
                        cols[2,],
                        cols[3,]
)
)

write.table(pct,paste0(gfcdir,"/color_table.txt"),row.names = F,col.names = F,quote = F)

#################### CONVERT TO BYTE
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(gfcdir,"tmp_reclass_segments.tif"),
               paste0(gfcdir,"tmp_byte_reclass_segments.tif")
))

################################################################################
## Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(gfcdir,"/color_table.txt"),
               paste0(gfcdir,"tmp_byte_reclass_segments.tif"),
               paste0(gfcdir,"tmp_pct_byte_reclass_segments.tif")
))

#################### Compress
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(gfcdir,"tmp_pct_byte_reclass_segments.tif"),
               paste0(gfcdir,"DD_2009_2014_druk_20170919.tif")
))



system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               paste0(gfcdir,"DD_2009_2014_druk_20170907.tif"),
               paste0(gfcdir,"stat_2009_2014_DD_druk_20170907.txt"),
               paste0(gfcdir,"DD_2009_2014_druk_20170907.tif")
))

stats_pixel <- read.table(paste0(gfcdir,"stat_2009_2014_DD_druk_20170907.txt"))

####### Clean
system(sprintf("rm %s",
               paste0(gfcdir,"tmp*.tif")
               ))

####### Time
Sys.time()-start_time
