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
  system("wget https://download.wetransfer.com/eu2/82fb49b5c5d41fd198a97b10bc42033620170813041404/gis_data_bhutan.zip?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1bmlxdWUiOiI4MmZiNDliNWM1ZDQxZmQxOThhOTdiMTBiYzQyMDMzNjIwMTcwODEzMDQxNDA0IiwicHJvZmlsZSI6ImV1MiIsImZpbGVuYW1lIjoiZ2lzX2RhdGFfYmh1dGFuLnppcCIsImVzY2FwZWQiOiJmYWxzZSIsImV4cGlyZXMiOjE1MDI2MDMzNTIsImNhbGxiYWNrIjoie1wiZm9ybWRhdGFcIjp7XCJhY3Rpb25cIjpcImh0dHBzOi8vYXBpLndldHJhbnNmZXIuY29tL2FwaS92MS90cmFuc2ZlcnMvODJmYjQ5YjVjNWQ0MWZkMTk4YTk3YjEwYmM0MjAzMzYyMDE3MDgxMzA0MTQwNC9yZWNpcGllbnRzLzBlMTUzMDJjNTcyZWMxZGIxMDY3NDU1NzYwYjk3MjdjMjAxNzA4MTMwNDE0MDRcIn0sXCJmb3JtXCI6e1wic3RhdHVzXCI6W1wicGFyYW1cIixcInN0YXR1c1wiXSxcImRvd25sb2FkX2lkXCI6XCIyNzUwMDM4Mjk1XCJ9fSJ9.6X4Yx_qDY0MJalNgkNi46oO2eEIxlbLCRkG3Md1JqtE")
  
  system("unzip gis_data_bhutan.zip" )
  
  
