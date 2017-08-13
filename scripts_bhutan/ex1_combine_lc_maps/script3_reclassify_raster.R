####################################################################################
#######    object: CLEAN AND COMBINE SHAPEFILES                 ####################
#######    Update : 2017/08/08                                  ####################
#######    contact: remi.dannunzio@fao.org                      ####################
####################################################################################
code_class <- read.csv("code_class.csv")

#################### COMPUTE OCCURENCE OF THE TRANSITION RASTER
system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               "change_951016.tif",
               "stats_change.txt",
               "change_951016.tif"
))


#################### READ STATISTICS AND RESEPARATE EACH DATE COMPONENT
df <- read.table("stats_change.txt")[,1:2]
names(df) <- c("chg_code","pix_count")

df$code95 <- as.numeric(substr(as.character(1000000 + df$chg_code),2,3))
df$code10 <- as.numeric(substr(as.character(1000000 + df$chg_code),4,5))
df$code16 <- as.numeric(substr(as.character(1000000 + df$chg_code),6,7))

df <- merge(df,code_class,by.x="code95",by.y="code",all.x=T)
names(df)[names(df) == "class"] <- "class95"

df <- merge(df,code_class,by.x="code10",by.y="code",all.x=T)
names(df)[names(df) == "class"] <- "class10"

df <- merge(df,code_class,by.x="code16",by.y="code",all.x=T)
names(df)[names(df) == "class"] <- "class16"

df <- df[,c("chg_code","pix_count","code95","code10","code16","class95","class10","class16")]

#################### Convert pixel to ha
df$area <- df$pix_count*30*30/10000

#################### Look at the dataset
head(df)
sum(df$area)

# plot(df$chg_code,df$area)
# summary(df$area)
# 
# plot(df$chg_code,log10(df$area))
# points(df[df$area<100,]$chg_code,log10(df[df$area<100,]$area),col="red")

quantile(df$area,seq(0,1,0.1))

my_cum_sum <- function(x){
  sum(head(arrange(df,desc(area)),x)$area)/sum(df$area)
}

#plot(sapply(1:nrow(df),my_cum_sum),ylim=c(0,1))

thresh <- 250

my_cum_sum(thresh)
arrange(df,desc(area))[thresh,]

areacut <- arrange(df,desc(area))[thresh,"area"]

df$size <- "small"
df[df$area >= areacut,]$size <- "big"

table(df$size)


#################### Identify transitions of forest loss (1 for old, 2 for recent)
df$loss <- 0
df[is.na(df)] <- "no_data"
df[df$class95 == "Forest" & df$class10 != "Forest" & df$class16 != "Forest",]$loss <- 1
df[df$class95 == "Forest" & df$class10 == "Forest" & df$class16 != "Forest",]$loss <- 2

table(df$loss)

arrange(df[df$loss > 0 & df$size == "big",],desc(area))


#################### Identify transitions of forest gain (1 for old, 2 for recent)
df$gain <- 0

df[df$class95 != "Forest" & df$class10 == "Forest" & df$class16 == "Forest",]$gain <- 1
df[df$class95 != "Forest" & df$class10 != "Forest" & df$class16 == "Forest",]$gain <- 2

table(df$gain)


#################### Reclassify with the following final legend
# 0  -> no data
# 1  -> other land
# 3  -> non forest
# 4  -> forest
# 11 -> old loss
# 12 -> recent loss
# 21 -> old gain
# 22 -> recent gain

df$newcode <- 1

df[df$code95 == 0 | df$code10 == 0 | df$code16 == 0,]$newcode <- 0

df[df$loss == 1 & df$size == "big",]$newcode <- 11
df[df$loss == 2 & df$size == "big",]$newcode <- 12

df[df$gain == 1 & df$size == "big",]$newcode <- 21
df[df$gain == 2 & df$size == "big",]$newcode <- 22

df[df$class95 == "Forest" & df$class10 == "Forest" & df$class16 == "Forest",]$newcode <- 4

df[df$class95 != "Forest" & df$class10 != "Forest" & df$class16 != "Forest",]$newcode <- 3

tapply(df$area,df$newcode,sum)

table(df$newcode)

write.table(df[,c("chg_code","newcode")],"reclass.txt",sep = " ",row.names = F,col.names = F)
write.csv(df,"all_transitions_simple.csv",row.names = F)


#################### RECLASSIFY THE CHANGE RASTER
system(sprintf("(echo %s; echo 1; echo 1; echo 2; echo 0) | oft-reclass -oi  %s  %s",
               "reclass.txt",
               "tmp_final_change_951016.tif",
               "change_951016.tif"
))

#################### SIEVE RESULTS
system(sprintf("gdal_sieve.py -st %s %s %s",
               3,
               "tmp_final_change_951016.tif",
               "tmp_sieve_final_change_951016.tif"))

#################### CONVERT TO BYTE
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               "tmp_sieve_final_change_951016.tif",
               "tmp_byte_sieve_final_change_951016.tif"
))

####################  CREATE A PSEUDO COLOR TABLE
cols <- col2rgb(c("black","lightgrey","grey","darkgreen","red","orange","lightblue","blue"))

pct <- data.frame(cbind(c(0,1,3,4,11,12,21,22),
                        cols[1,],
                        cols[2,],
                        cols[3,]
                        )
                  )

write.table(pct,paste0("color_table.txt"),row.names = F,col.names = F,quote = F)

################################################################################
## Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0("color_table.txt"),
               paste0("tmp_byte_sieve_final_change_951016.tif"),
               paste0("tmp_pct_sieve_final_change_951016.tif")
))

#################### COMPRESS RESULTS
system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
               "tmp_pct_sieve_final_change_951016.tif",
               "final_change_951016_simple_legend.tif"))

#################### DELETE TEMP FILES
system(sprintf(paste0("rm tmp*.tif")))



