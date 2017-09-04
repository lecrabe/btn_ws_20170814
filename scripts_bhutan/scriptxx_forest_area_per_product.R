####################################################################################
#######    object: COMPUTE FOREST AREA FOLLOWING EACH PRODUCT   ####################
#######    Update : 2017/08/15                                  ####################
#######    contact: remi.dannunzio@fao.org                      ####################
####################################################################################

#################### Define AOI as country boundaries 
workdir    <- "/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/bhutan/gis_data_bhutan/"

setwd(workdir)

gfc_folder <- paste0(workdir,"gfc_2015/")
glc_folder <- paste0(workdir,"glc_2000_2010/")
esa_folder <- paste0(workdir,"esa_cci_1992-2015_v2.0.7/")

aoiname    <- paste0(workdir,"boundaries_bhutan/bhutan.shp")
aoi        <- readOGR(aoiname,"bhutan")

####################################################################################################    
#####################################    ESA DATASET
####################################################################################################
list <- list.files(paste0(esa_folder,"esa_cci_individual_maps/"),pattern = glob2rx("aoi*.tif"))

df <- read.csv("esa_cci_1992-2015_v2.0.7/legend_cci.csv")[,1:2]
names(df) <- c("class","descr")

for(layer in list ){
  print(layer)
  base <- substr(layer,1,nchar(layer)-4)
  year <- substr(base,nchar(base)-3,nchar(base))

  system(sprintf("gdalwarp -t_srs EPSG:5266 -co COMPRESS=LZW %s %s",
                 paste0(esa_folder,"esa_cci_individual_maps/",layer),
                 paste0(esa_folder,"esa_cci_individual_maps/druk",layer)
  ))

  #################### Crop the CCI 1992-2015 ESA product into the AOI
  system(sprintf("oft-cutline_crop.py -v %s -i %s -o %s",
                 aoiname,
                 paste0(esa_folder,"esa_cci_individual_maps/druk",layer),
                 paste0(esa_folder,"esa_cci_individual_maps/crop_druk",layer)
  ))

  system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
                 paste0(esa_folder,"esa_cci_individual_maps/crop_druk",layer),
                 paste0(esa_folder,"esa_cci_individual_maps/crop_druk",base,".txt"),
                 paste0(esa_folder,"esa_cci_individual_maps/crop_druk",layer)
  ))
  
  tmp <- read.table(paste0(esa_folder,"esa_cci_individual_maps/crop_druk",base,".txt"))[,1:2]
  names(tmp) <- c("class",paste0("pix_",year))
  df <- merge(df,tmp,all.x=T)
}
df[is.na(df)] <- 0

pix <- res(raster(paste0(esa_folder,"esa_cci_individual_maps/crop_druk",layer)))[1]
df[,3:ncol(df)] <- df[,3:ncol(df)]*pix*pix/10000 

write.csv(df,"stats_esa_cci.csv",row.names = F)



####################################################################################################    
#####################################    GFC DATASET
####################################################################################################

system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfc_folder,"gfc_tc2000_bhutan.tif"),
               paste0(gfc_folder,"gfc_tc2000_gt10_bhutan.tif"),
               "(A>10)*A"
))
  
system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               paste0(gfc_folder,"gfc_lossyear_bhutan.tif"),
               paste0(gfc_folder,"gfc_tc2000_gt10_bhutan.tif"),
               paste0(gfc_folder,"gfc_lossyear_gt10_bhutan.tif"),
               "(B>10)*A"
))             

list <- list.files(paste0(gfc_folder),pattern = glob2rx("gfc*.tif"))
list <- c("gfc_gain_bhutan.tif","gfc_lossyear_gt10_bhutan.tif","gfc_tc2000_gt10_bhutan.tif")

for(layer in list ){
  print(layer)
  base <- substr(layer,1,nchar(layer)-4)

  system(sprintf("gdalwarp -t_srs EPSG:5266 -co COMPRESS=LZW %s %s",
                 paste0(gfc_folder,layer),
                 paste0(gfc_folder,"druk",layer)
  ))
  
  #################### Crop the CCI 1992-2015 ESA product into the AOI
  system(sprintf("oft-cutline_crop.py -v %s -i %s -o %s",
                 aoiname,
                 paste0(gfc_folder,"druk",layer),
                 paste0(gfc_folder,"crop_druk",layer)
  ))
  
  system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
                 paste0(gfc_folder,"crop_druk",layer),
                 paste0(gfc_folder,"crop_druk",base,".txt"),
                 paste0(gfc_folder,"crop_druk",layer)
  ))
}

pix <- res(raster(paste0(gfc_folder,"crop_druk",layer)))[1]

write.csv(df,"stats_esa_cci.csv",row.names = F)


####################################################################################################    
#####################################    National Maps DATASET
####################################################################################################

system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               "lulc_change/shp1995.tif",
               "lulc_change/shp1995.txt",
               "lulc_change/shp1995.tif"
))

system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               "lulc_change/shp2010.tif",
               "lulc_change/shp2010.txt",
               "lulc_change/shp2010.tif"
))

system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               "lulc_change/shp2016.tif",
               "lulc_change/shp2016.txt",
               "lulc_change/shp2016.tif"
))

df95 <- read.table("lulc_change/shp1995.txt")[,1:2]
df10 <- read.table("lulc_change/shp2010.txt")[,1:2]
df16 <- read.table("lulc_change/shp2016.txt")[,1:2]

code <- read.csv("lulc_change/code_class.csv")

df <- merge(code,df95,by.x="code",by.y="V1",all.x=T)
df <- merge(df,df10,by.x="code",by.y="V1",all.x=T)
df <- merge(df,df16,by.x="code",by.y="V1",all.x=T)

names(df) <- c("code","descr","area1995","area2010","area2016")

df[is.na(df)] <- 0

pix <- res(raster("lulc_change/shp2016.tif"))[1]
df[,3:ncol(df)] <- df[,3:ncol(df)]*pix*pix/10000 

write.csv(df,"stats_national_maps.csv",row.names = F)

####################################################################################################    
#####################################    Unique Forestry
####################################################################################################

system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               "Bhutan_Drivers_Study/RASTER/2000_lulc_cc.tif",
               "Bhutan_Drivers_Study/RASTER/stats_2000_lulc_cc.txt",
               "Bhutan_Drivers_Study/RASTER/2000_lulc_cc.tif"
))

system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               "Bhutan_Drivers_Study/RASTER/2010_lulc_cc.tif",
               "Bhutan_Drivers_Study/RASTER/stats_2010_lulc_cc.txt",
               "Bhutan_Drivers_Study/RASTER/2010_lulc_cc.tif"
))

system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               "Bhutan_Drivers_Study/RASTER/2015_lulc_cc.tif",
               "Bhutan_Drivers_Study/RASTER/stats_2015_lulc_cc.txt",
               "Bhutan_Drivers_Study/RASTER/2015_lulc_cc.tif"
))


df00 <- read.table("Bhutan_Drivers_Study/RASTER/stats_2000_lulc_cc.txt")[,1:2]
df10 <- read.table("Bhutan_Drivers_Study/RASTER/stats_2010_lulc_cc.txt")[,1:2]
df15 <- read.table("Bhutan_Drivers_Study/RASTER/stats_2015_lulc_cc.txt")[,1:2]

code <- read.csv("Bhutan_Drivers_Study/legend_unique.csv")

df <- merge(code,df00,by.x="code",by.y="V1",all.x=T)
df <- merge(df,df10,by.x="code",by.y="V1",all.x=T)
df <- merge(df,df15,by.x="code",by.y="V1",all.x=T)

names(df) <- c("code","descr","area2000","area2010","area2015")

df[is.na(df)] <- 0

pix <- res(raster("Bhutan_Drivers_Study/RASTER/2015_lulc_cc.tif"))[1]
df[,3:ncol(df)] <- df[,3:ncol(df)]*pix*pix/10000 

write.csv(df,"stats_unique.csv",row.names = F)


####################################################################################################    
#####################################    GLC dataset
####################################################################################################
setwd(glc_folder)

#################### Crop the DD to country boundaries
system(sprintf("oft-cutline_crop.py -v %s -i %s -o %s",
               "../boundaries_bhutan/bhutan.shp",
               "glc_bhutan_druk_2000lc030.tif",
               "crop_glc_bhutan_druk_2000lc030.tif"
))

system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               "crop_glc_bhutan_druk_2000lc030.tif",
               "stats_2000lc030.txt",
               "crop_glc_bhutan_druk_2000lc030.tif"
))

#################### Crop the DD to country boundaries
system(sprintf("oft-cutline_crop.py -v %s -i %s -o %s",
               "../boundaries_bhutan/bhutan.shp",
               "glc_bhutan_druk_2010lc030.tif",
               "crop_glc_bhutan_druk_2010lc030.tif"
))

system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               "crop_glc_bhutan_druk_2010lc030.tif",
               "stats_2010lc030.txt",
               "crop_glc_bhutan_druk_2010lc030.tif"
))


df00 <- read.table("stats_2000lc030.txt")[,1:2]
df10 <- read.table("stats_2010lc030.txt")[,1:2]

code <- read.csv("legend_glc.csv")

df <- merge(code,df00,by.x="code",by.y="V1",all.x=T)
df <- merge(df,df10,by.x="code",by.y="V1",all.x=T)

names(df) <- c("code","descr","area2000","area2010")

df[is.na(df)] <- 0

pix <- res(raster("glc_bhutan_druk_2000lc030.tif"))[1]
df[,3:ncol(df)] <- df[,3:ncol(df)]*pix*pix/10000 

write.csv(df,"stats_glc.csv",row.names = F)
