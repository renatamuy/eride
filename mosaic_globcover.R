#' ----
#' Nesi
#' script: mosaic rasters of interest for large portions of Asia
#' author: Renata Muylaert
#' date: 2022-05-18
#' ----

# Clean objects and memory size, vanish with scinot, load packages ---------------------

#rm(list = ls())
#gc() 
options(digits = 7, scipen = 999)
#memory.limit(size = 1.75e13)

library(raster)
library(rgdal)
library(sp) 
library(gdalUtils)

workdir = "/scale_wlg_nobackup/filesets/nobackup/massey03262/strata"
setwd(workdir)

# Set timer

start <- print(Sys.time())

suppressPackageStartupMessages(library(rgdal)) 

  files_list <- paste(dir(workdir))
  
  nome.arq.wgs84 <- paste("globcover_world.tif", sep="")
  
  # Mosaic
  
  mosaic_rasters(gdalfile = files_list, dst_dataset = nome.arq.wgs84, of = "GTiff")
  
  #forceot = "Float32" check
  
  print("Mosaicou")

  end <- print(Sys.time())
  
  print(end-start)

#----------------------------------------------------------------------------------
