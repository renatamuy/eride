# Management layer


require(terra)
require(rgrass)
require(rnaturalearth)
require(sf)
require(ggplot2)
library(dplyr)
#devtools::install_github("G-Thomson/Manu")
library(Manu)
library(ggraph)
library(tidygraph)
library(maps)
library(sfnetworks)
library(ggspatial)


lesiv <- 'D:/OneDrive - Massey University/hostland/data/lesiv_zenodo/FML_v3-2_with-colorbar.tif'

manrast <- rast(lesiv)
  
plot(manrast)

# Get shapefile of districts

keep <- c("Banten",
          "West Java", 
          "Central Java",   
          "Yogyakarta"  ,
          "East Java"      ) # "Bali"

#subset_districts <- ind_districts[ind_districts$name_en %in% keep, ]
#sf::st_write(subset_districts, 'subset_districts.shp')

vector_file <- "C://Users//rdelaram//Documents//GitHub//eride/data//subset_districts.shp" 
regions <- read_sf(vector_file)
regions <- regions[regions$name_en %in% keep, ]

regions

result_management <- terra::extract(raster_data, regions, fun=table, na.rm = TRUE)

result_management

# Open gravity model results as linestring to match shapefile

edges_sf <- st_read("edges_sf.shp")



