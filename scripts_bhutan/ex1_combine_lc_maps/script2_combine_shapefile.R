####################################################################################
#######    object: CLEAN AND COMBINE SHAPEFILES                 ####################
#######    Update : 2017/08/08                                  ####################
#######    contact: remi.dannunzio@fao.org                      ####################
####################################################################################

#################### READ SHAPEFILES
# shp95 <- readOGR(dsn="LUPP1995.shp",layer = "LUPP1995" )
# shp10 <- readOGR(dsn="lc_2010.shp" ,layer = "lc_2010" )
# shp16 <- readOGR(dsn="LULC2016.shp",layer = "LULC2016" )

shp95 <- readOGR(dsn="lc_1995_sel.shp",layer = "lc_1995_sel" )
shp10 <- readOGR(dsn="lc_2010_sel.shp",layer = "lc_2010_sel" )
shp16 <- readOGR(dsn="lc_2016_sel.shp",layer = "lc_2016_sel" )

bckup95 <- shp95
bckup10 <- shp10
bckup16 <- shp16

#################### EXTRACT DBF AND CHECK DISTRIBUTION OF CLASSES
dbf95 <- shp95@data
dbf10 <- shp10@data
dbf16 <- shp16@data

#################### DETERMINE EXTENT OF BOTH SHAPEFILES
ext <- extent(shp95)

ext@xmin <- min(extent(shp95)@xmin,extent(shp10)@xmin,extent(shp16)@xmin)
ext@ymin <- min(extent(shp95)@ymin,extent(shp10)@ymin,extent(shp16)@ymin)

ext@xmax <- max(extent(shp95)@xmax,extent(shp10)@xmax,extent(shp16)@xmax)
ext@ymin <- min(extent(shp95)@ymin,extent(shp10)@ymin,extent(shp16)@ymin)


#################### CHECK LAND COVER CLASSES
names(dbf95)
names(dbf10)
names(dbf16)

names(dbf95)[names(dbf95) == "LCover"]     <- "old_class"
names(dbf10)[names(dbf10) == "Land_Cover"] <- "old_class"
names(dbf16)[names(dbf16) == "CLASS"]      <- "old_class"

table(dbf95$old_class)
table(dbf10$old_class)
table(dbf16$old_class)

#################### GENERATE UNIQUE POLYGON ID
dbf95$polyid <- row(dbf95)[,1]
dbf10$polyid <- row(dbf10)[,1]
dbf16$polyid <- row(dbf16)[,1]

#################### Harmonize land cover class names
harmonize <- function(dbf,att){
  
  dbf$new_class <- dbf[,att]
  
  tryCatch({ dbf[grep("outcrop",dbf[,att]     ,ignore.case = TRUE),]$new_class  <- "Rocky outcrops"}, error=function(e){cat("Configuration impossible \n")})
  tryCatch({ dbf[grep("Scrub",dbf[,att]       ,ignore.case = TRUE),]$new_class  <- "Scrub"      },    error=function(e){cat("Configuration impossible \n")})
  tryCatch({ dbf[grep("Forest",dbf[,att]      ,ignore.case = TRUE),]$new_class  <- "Forest"     },    error=function(e){cat("Configuration impossible \n")})
  tryCatch({ dbf[grep("Snow",dbf[,att]        ,ignore.case = TRUE),]$new_class  <- "Snow"       },    error=function(e){cat("Configuration impossible \n")})
  tryCatch({ dbf[grep("Landsli",dbf[,att]     ,ignore.case = TRUE),]$new_class  <- "Landslides" },    error=function(e){cat("Configuration impossible \n")})
  tryCatch({ dbf[grep("Water",dbf[,att]       ,ignore.case = TRUE),]$new_class  <- "Water"      },    error=function(e){cat("Configuration impossible \n")})
  tryCatch({ dbf[grep("Agriculture",dbf[,att] ,ignore.case = TRUE),]$new_class  <- "Agriculture"},    error=function(e){cat("Configuration impossible \n")})
  tryCatch({ dbf[grep("Marshy",dbf[,att]      ,ignore.case = TRUE),]$new_class  <- "Marshy areas"},   error=function(e){cat("Configuration impossible \n")})
  
  dbf
}

dbfh95  <- harmonize(dbf95,"old_class")
dbfh10  <- harmonize(dbf10,"old_class")
dbfh16  <- harmonize(dbf16,"old_class")

table(dbfh10$old_class)
table(dbfh10$new_class)

#################### DETERMINE LIST OF CLASSES FOR EACH DATASET
(list_class95 <- unique(dbfh95$new_class))
(list_class10 <- unique(dbfh10$new_class))
(list_class16 <- unique(dbfh16$new_class))

list_class <- unique(unlist(c(list_class16,list_class95,list_class10)))
list_class <- list_class[order(list_class)]

code_class <- data.frame(cbind(list_class,1:length(list_class)))
names(code_class) <- c("class","code")

code_class

write.csv(code_class,"code_class.csv",row.names = F)

#################### MERGE THESE CODES IN DBF-Harmonized
dbfh95 <- merge(dbfh95,code_class,by.x="new_class",by.y="class",all.x=T)
dbfh10 <- merge(dbfh10,code_class,by.x="new_class",by.y="class",all.x=T)
dbfh16 <- merge(dbfh16,code_class,by.x="new_class",by.y="class",all.x=T)

dbfh95 <- dbfh95[,c("polyid","old_class","new_class","code")]
dbfh10 <- dbfh10[,c("polyid","old_class","new_class","code")]
dbfh16 <- dbfh16[,c("polyid","old_class","new_class","code")]

#################### EXPORT THE HARMONIZED SHAPEFILES
shp95@data <- arrange(dbfh95,polyid)
shp10@data <- arrange(dbfh10,polyid)
shp16@data <- arrange(dbfh16,polyid)

writeOGR(shp95,"shp1995.shp","shp1995",driver="ESRI Shapefile",overwrite_layer = T)
writeOGR(shp10,"shp2010.shp","shp2010",driver="ESRI Shapefile",overwrite_layer = T)
writeOGR(shp16,"shp2016.shp","shp2016",driver="ESRI Shapefile",overwrite_layer = T)


#################### RASTERIZE FIRST SHAPEFILE AT 30m RESOLUTION (8Bit and 32Bit version)
system(sprintf("gdal_rasterize -a %s -l %s -co COMPRESS=LZW -te %s %s %s %s -tr %s %s -ot Byte %s %s",
               "code",
               "shp1995",
               ext@xmin,ext@ymin,ext@xmax,ext@ymax,
               30,30,
               "shp1995.shp",
               "shp1995.tif"
))

system(sprintf("gdal_translate -co COMPRESS=LZW -ot UInt32 %s %s",
               "shp1995.tif",
               "shp1995_int32.tif"
))

#################### RASTERIZE THIRD SHAPEFILE AT 30m RESOLUTION (8Bit and 32Bit version)
system(sprintf("gdal_rasterize -a %s -l %s -co COMPRESS=LZW -te %s %s %s %s -tr %s %s -ot Byte %s %s",
               "code",
               "shp2010",
               ext@xmin,ext@ymin,ext@xmax,ext@ymax,
               30,30,
               "shp2010.shp",
               "shp2010.tif"
))


system(sprintf("gdal_translate -co COMPRESS=LZW -ot UInt32 %s %s",
               "shp2010.tif",
               "shp2010_int32.tif"
))

#################### RASTERIZE SECOND SHAPEFILE AT 30m RESOLUTION (8Bit and 32Bit version)
system(sprintf("gdal_rasterize -a %s -l %s -co COMPRESS=LZW -te %s %s %s %s -tr %s %s -ot Byte %s %s",
               "code",
               "shp2016",
               ext@xmin,ext@ymin,ext@xmax,ext@ymax,
               30,30,
               "shp2016.shp",
               "shp2016.tif"
))

system(sprintf("gdal_translate -co COMPRESS=LZW -ot UInt32 %s %s",
               "shp2016.tif",
               "shp2016_int32.tif"
))


#################### COMBINE ALL RASTERS INTO A 3_DATES_CODE RASTER
system(sprintf("gdal_calc.py -A %s -B %s -C %s --type=UInt32 --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               "shp1995_int32.tif",
               "shp2010_int32.tif",
               "shp2016_int32.tif",
               "change_951016.tif",
               "A*10000+B*100+C"
))




