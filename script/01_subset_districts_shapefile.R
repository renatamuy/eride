# Get shapefile of a subset districts

target <- ne_countries(type = "countries", country = c('Bangladesh',
                                                       'Bhutan',
                                                       'Brunei',
                                                       'Cambodia',
                                                       'China', 
                                                       'India',
                                                       'Indonesia',
                                                       'Laos',
                                                       'Malaysia',
                                                       'Myanmar',
                                                       'Nepal',
                                                       'Philippines',
                                                       'Singapore', 
                                                       'Sri Lanka',
                                                       'Thailand',
                                                       'Timor-Leste',
                                                       'Vietnam'))



# Get shapefile of districts
# Provinces to keep
keep <- c("Banten",
          "West Java", 
          "Central Java",   
          "Yogyakarta"  ,
          "East Java"      ) # "Bali"

#subset_districts <- ind_districts[ind_districts$name_en %in% keep, ]
#sf::st_write(subset_districts, 'subset_districts.shp')

#keep <- c("Banten",
#         "West Java", 
#        "Central Java",   
#       "Yogyakarta"  ,
#      "East Java", "Bali"  ) # 
#subset_districts <- ind_districts[ind_districts$name_en %in% keep, ]


#sf::st_write(subset_districts, 'subset_districts.shp')
