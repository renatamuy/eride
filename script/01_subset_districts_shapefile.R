# Get shapefile of a subset districts

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
