####################################################################################
#######    object: DOWNLOAD DATA FOR WORKSHOP                   ####################
#######    Update : 2017/08/14                                  ####################
#######    contact: remi.dannunzio@fao.org                      ####################
####################################################################################

####################################################################################
# FAO declines all responsibility for errors or deficiencies in the database or 
# software or in the documentation accompanying it, for program maintenance and 
# upgrading as well as for any # damage that may arise from them. FAO also declines 
# any responsibility for updating the data and assumes no responsibility for errors 
# and omissions in the data provided. Users are, however, kindly asked to report any 
# errors or deficiencies in this product to FAO.
####################################################################################

############### DOWNLOAD WORKSHOP DATA
  setwd("~/btn_ws_20170814/")
  #system("wget -O tmp.zip \"https://drive.google.com/uc?export=download&id=0B4Jq8yMRjKLjek11OVFSWlBTUFU\"")
  #system("wget -O tmp.zip \"https://drive.google.com/uc?export=download&id=0B4Jq8yMRjKLjNEllLUNoV0o2bjg\"")
  system("wget https://www.dropbox.com/s/vzzp94sftspzrad/gis_data_bhutan_h.zip?dl=0")
  system("unzip gis_data_bhutan_h.zip?dl=0" )
  system("rm *.zip")
  
