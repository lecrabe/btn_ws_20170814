####################################################################################
#######    object: EXTRACT BY DISTRICT                          ####################
#######    Update : 2017/08/15                                  ####################
#######    contact: remi.dannunzio@fao.org                      ####################
####################################################################################

aoi   <- readOGR("../boundaries_bhutan/Dzongkhag.shp","Dzongkhag")
ddmap <- raster("final_change_951016_simple_legend.tif")

plot(aoi)
plot(ddmap)

dis   <- aoi[aoi@data$DzgName == "Thimphu",]
dddis <- mask(crop(x = ddmap,y=dis),dis)

plot(dis)
plot(dddis,add=T)

####### Compute zonal stats for LOSSES
system(sprintf("oft-zonal_large_list.py -i %s -o %s -um %s",
               "final_change_951016_simple_legend.tif",
               "stats_by_district.txt",
               "../boundaries_bhutan/Dzongkhag.shp"
))

ss <- read.table("stats_by_district.txt")
ss[,2:ncol(ss)] <- ss[,2:ncol(ss)]*res(ddmap)[1]*res(ddmap)[1]/10000
names(ss) <- c("feat","total","nodata",paste0("class",1:(ncol(ss)-3)))
ss <- ss[,colSums(ss)>0]
classes <- names(ss)
ss$district <- aoi@data$DzgName

ss <- ss[,c("district",classes)]


