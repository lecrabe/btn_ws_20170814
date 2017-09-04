####################################################################################
#######    object: COMPUTE FOREST AREA FOLLOWING EACH PRODUCT   ####################
#######    Update : 2017/08/15                                  ####################
#######    contact: remi.dannunzio@fao.org                      ####################
####################################################################################
library(foreign)
library(plyr)
library(rgeos)
library(rgdal)
library(raster)
library(ggplot2)

options(stringsAsFactors = F)

#################### Define AOI as country boundaries 
workdir    <- "/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/bhutan/gis_data_bhutan/"

setwd(workdir)

pts <- read.csv("NFI_bhutan_2012_2016/plot.csv")
ras <- raster("Bhutan_Drivers_Study/RASTER/2015_lulc_cc_geo.tif")

names(pts)

pt_df_geo <- SpatialPointsDataFrame(
  coords = pts[!is.na(pts$plot_location_x),c("plot_location_x","plot_location_y")],
  data   = data.frame(pts[!is.na(pts$plot_location_x),]),
  proj4string=CRS("+init=epsg:4326")
)


pt_df_geo@data$NFI <- extract(ras,pt_df_geo)

points <- pt_df_geo@data

summary(points$NFI)
summary(points$stand_description_canopy_closure)

points$CC_cluster <- 4
points[points$stand_description_canopy_closure > 10 & points$stand_description_canopy_closure <= 30,]$CC_cluster <- 1
points[points$stand_description_canopy_closure > 30 & points$stand_description_canopy_closure <= 50,]$CC_cluster <- 2
points[points$stand_description_canopy_closure > 50 ,]$CC_cluster <- 3

table(points$CC_cluster,points$NFI_cluster)

points$NFI_cluster <- 4
points[points$NFI %in% c(7,10,13),]$NFI_cluster <- 1
points[points$NFI %in% c(6,9,12),]$NFI_cluster  <- 2
points[points$NFI %in% c(5,8,11),]$NFI_cluster  <- 3

rcl <- cbind(1:17,c(4,4,4,4,3,2,1,3,2,1,3,2,1,4,4,4,4))
reclass <- reclassify(ras,rcl)

write.csv(points,"/home/dannunzio/sae_design_reclass_2016_CC/intersection.csv",row.names = F)
writeRaster(reclass,"/home/dannunzio/reclass_2016_CC.tif",overwrite=T)

points$verif <- extract(reclass,pt_df_geo)
table(points$verif,points$NFI_cluster)
