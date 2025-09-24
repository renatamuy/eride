################################################################################
# Publication: Upscaling effects on infectious disease emergence risk emphasize 
# the need for local planning in primary prevention within biodiversity hotspots
# Script: Indonesia adm limits shapefile
# Author: R. L. Muylaert
# Date: 2025
# R version 4.5.1
################################################################################

require(sf)
require(rnaturalearth)

ind_provinces <- rnaturalearth::ne_states("Indonesia", returnclass = "sf")
unique(ind_provinces$type_en)
unique(ind_provinces$name_en)


# Provinces to keep
keep <- c("Banten",
          "Jakarta", 
          "West Java", 
          "Central Java",   
          "Yogyakarta"  ,
          "East Java" ,
          "Bali")

subset_districts <- ind_provinces[ind_provinces$name_en %in% keep, ]

setwd('../data')

Export 
#sf::st_write(subset_districts, 'subset_districts.shp',  append=FALSE)

unique(subset_districts$name_en) 

unique(subset_districts$type_en)
data.frame(subset_districts$name_en,subset_districts$type_en) 

#Banten, Jakarta, West Java, Central Java, Yogyakarta, East Java, Bali.
