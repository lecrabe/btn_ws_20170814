####################################################################################
#######    object: CLEAN AND COMBINE SHAPEFILES                 ####################
#######    Update : 2017/08/08                                  ####################
#######    contact: remi.dannunzio@fao.org                      ####################
####################################################################################


#################### COMBINE ALL RASTERS INTO A 3_DATES_CODE RASTER
system(sprintf("gdal_translate -co COMPRESS=LZW -a_nodata 0 -ot UInt32 %s %s",
               "../esa_cci_1992-2015_v2.0.7/esa_cci_individual_maps/aoi_esa_cci_bhutan_contour_2002.tif",
               "../esa_cci_1992-2015_v2.0.7/tmp32_aoi_esa_cci_bhutan_contour_2002.tif"
))

system(sprintf("gdal_translate -co COMPRESS=LZW -a_nodata 0 -ot UInt32 %s %s",
               "../esa_cci_1992-2015_v2.0.7/esa_cci_individual_maps/aoi_esa_cci_bhutan_contour_2012.tif",
               "../esa_cci_1992-2015_v2.0.7/tmp32_aoi_esa_cci_bhutan_contour_2012.tif"
))

system(sprintf("gdal_calc.py -A %s -B %s --type=UInt32 --NoDataValue=0 --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               "../esa_cci_1992-2015_v2.0.7/tmp32_aoi_esa_cci_bhutan_contour_2002.tif",
               "../esa_cci_1992-2015_v2.0.7/tmp32_aoi_esa_cci_bhutan_contour_2012.tif",
               "../esa_cci_1992-2015_v2.0.7/change_esa_2002-2012.tif",
               "(A>0)*(B>0)*(A*1000+B)"
))

system(sprintf("gdalwarp -t_srs EPSG:5266 -co COMPRESS=LZW %s %s",
               "../esa_cci_1992-2015_v2.0.7/change_esa_2002-2012.tif",
               "../esa_cci_1992-2015_v2.0.7/change_esa_2002-2012_druk.tif"
))

system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               "../esa_cci_1992-2015_v2.0.7/change_esa_2002-2012_druk.tif",
               "../esa_cci_1992-2015_v2.0.7/stats_esa_change.txt",
               "../esa_cci_1992-2015_v2.0.7/change_esa_2002-2012_druk.tif"
))

df <- read.table("../esa_cci_1992-2015_v2.0.7/stats_esa_change.txt")[,1:2]
names(df) <- c("chg_code","pix_count")

code_class <- read.csv("../esa_cci_1992-2015_v2.0.7/legend_cci.csv")

df$code02 <- as.numeric(substr(as.character(1000000 + df$chg_code),2,4))
df$code12 <- as.numeric(substr(as.character(1000000 + df$chg_code),5,7))

df <- merge(df,code_class[,1:2],by.x="code02",by.y="NB_LAB",all.x=T)
names(df)[names(df) == "LCCOwnLabel"] <- "class02"

df <- merge(df,code_class[,1:2],by.x="code12",by.y="NB_LAB",all.x=T)
names(df)[names(df) == "LCCOwnLabel"] <- "class12"

size <- res(raster("../esa_cci_1992-2015_v2.0.7/change_esa_2002-2012_druk.tif"))[1]

#################### Convert pixel to ha
df$area <- df$pix_count*size*size/10000

#################### Define "with trees" in 2002 and 2012
df$tree02 <- "no"
df$tree12 <- "no"

df[grep("Tree",df$class02,ignore.case = T),]$tree02 <- "low" # Take all code containing "tree"
df[grep("Tree",df$class02,ignore.case = F),]$tree02 <- "high" # Take only code starting with "Tree"

df[grep("Tree",df$class12,ignore.case = T),]$tree12 <- "low" # Take all code containing "tree"
df[grep("Tree",df$class12,ignore.case = F),]$tree12 <- "high" # Take only code starting with "Tree"


#################### Define change
df$change <- 0
df[df$code12 != df$code02,]$change  <- 1


#################### Define BIG and SMALL
my_cum_sum <- function(x){sum(head(arrange(df,desc(area)),floor(x))$area)/sum(df$area)}

target <- 0.99
precision <- 0.005

right <- nrow(df)
left  <- 0
thresh <- (right-left)/2+left

while(abs(my_cum_sum(thresh)-target) > precision ){
  
  thresh <- (right-left)/2+left
  print(my_cum_sum(thresh))
  
  if(my_cum_sum(thresh) > target + precision){
    right <- thresh
    }
  if(my_cum_sum(thresh) < target - precision){
    left  <- thresh
    }
}

arrange(df,desc(area))[thresh,]
areacut <- arrange(df,desc(area))[thresh,"area"]

df$size <- "small"
df[df$area >= areacut,]$size <- "big"

#################### Reclassify with the following final legend
# 0  -> no data
# 1  -> other
# 3  -> non tree stable
# 4  -> tree stable
# 11 -> deforestation
# 12 -> degradation
# 21 -> reforestation/regeneration


df$newcode <- 1

df[df$tree02 == "no" & df$tree12 == "no",]$newcode <- 3
df[df$tree02 == "no" & df$tree12 == "high",]$newcode <- 21
df[df$tree02 == "no" & df$tree12 == "low",]$newcode <- 22

df[df$tree02 != "no" & df$change == 0,]$newcode <- 4
df[df$tree02 != "no" & df$tree12 == "no",]$newcode <- 11
df[df$tree02 == "high" & df$tree12 != "no" & df$change == 1,]$newcode <- 12

tapply(df$area,df$newcode,sum)

table(df$chg_code,df$newcode)

write.table(df[,c("chg_code","newcode")],"../esa_cci_1992-2015_v2.0.7/reclass.txt",sep = " ",row.names = F,col.names = F)
write.csv(df,"../esa_cci_1992-2015_v2.0.7/transitions_esa_2002_2012.csv",row.names = F)

#################### RECLASSIFY THE CHANGE RASTER
system(sprintf("(echo %s; echo 1; echo 1; echo 2; echo 0) | oft-reclass -oi  %s  %s",
               "../esa_cci_1992-2015_v2.0.7/reclass.txt",
               "../esa_cci_1992-2015_v2.0.7/tmp_DD_esa_2002-2012_druk.tif",
               "../esa_cci_1992-2015_v2.0.7/change_esa_2002-2012_druk.tif"
               
))

#################### CONVERT TO BYTE
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               "../esa_cci_1992-2015_v2.0.7/tmp_DD_esa_2002-2012_druk.tif",
               "../esa_cci_1992-2015_v2.0.7/tmp_byte_DD_esa_2002-2012_druk.tif"
))

####################  CREATE A PSEUDO COLOR TABLE
cols <- col2rgb(c("black","lightgrey","grey","darkgreen","red","orange","purple","blue"))

pct <- data.frame(cbind(c(0,1,3,4,11,12,21,22),
                        cols[1,],
                        cols[2,],
                        cols[3,]
)
)

write.table(pct,paste0("../esa_cci_1992-2015_v2.0.7/color_table.txt"),row.names = F,col.names = F,quote = F)

################################################################################
## Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0("../esa_cci_1992-2015_v2.0.7/color_table.txt"),
               "../esa_cci_1992-2015_v2.0.7/tmp_byte_DD_esa_2002-2012_druk.tif",
               "../esa_cci_1992-2015_v2.0.7/tmp_pct_DD_esa_2002-2012_druk.tif"
))

#################### COMPRESS RESULTS
system(sprintf("gdal_translate -co COMPRESS=LZW -ot Byte %s %s",
               "../esa_cci_1992-2015_v2.0.7/tmp_pct_DD_esa_2002-2012_druk.tif",
               "../esa_cci_1992-2015_v2.0.7/DD_esa_2002-2012_druk.tif"))

#################### DELETE TEMP FILES
system(sprintf(paste0("rm ../esa_cci_1992-2015_v2.0.7/tmp*.tif")))

