
require(rgrass)
require(terra)
require(sf)

#setwd('C://Users//rdelaram//Documents//GitHub//eride//data//')
# Find a spacious dir
setwd('G:/')

# Find grass on Linux
#grassDir='/opt/nesi/CS400_centos7_bdw/GRASS/8.2.1-gimkl-2022a/grass82'

# Find grass on Windows
grassDir='C:/Program Files/GRASS GIS 8.2'

# Set the desired environment --------------------------------------------------------------------------------

# Import and reproject pop for pop at risk (PAR) calculation
pop <- 'G:/indonesia/idn_ppp_2020.tif' # 100 m

rgrass::initGRASS(gisBase = grassDir,
                  SG = rast(pop),
                  gisDbase = "grassdb",
                  location = "voronoi",  
                  mapset = "PERMANENT",
                  override = TRUE, 
                  remove_GISRC = TRUE)

rgrass::execGRASS("r.in.gdal",
                  input = pop,
                  output = "pop",
                  flags = c("overwrite"))

rgrass::execGRASS("g.list", type = "raster")
execGRASS("g.region", flags = "p", intern = TRUE)
execGRASS("r.info", map="pop")

# Step 1: Calculate 95th percentile
execGRASS("r.quantile", input="pop", percentiles=95, file="quantile_95.txt")

quantile_contents <- readLines("quantile_95.txt")

split_values <- strsplit(quantile_contents[1], ":")[[1]]

percentile_value <- as.numeric(split_values[3])  

# sharp round it
percentile_value <- round(percentile_value) 

# Rules
# Zero is not necessary bro!
#0 thru 5 = 0
#* = 1
#

#0 thru 5 = NULL
#* = 1
#

#rules_file <- "my_reclass_rule.txt"
#writeLines(reclass_rules, con = rules_file)

rules_file_path <- file.path(getwd(), "my_reclass_rule.txt")

# execGRASS("g.remove", type="raster", name="above_95th_percentile", flags="f")

# (omg this was stressful!)
execGRASS("r.reclass", input="pop", output="above_95th_percentile", rules=rules_file)

rgrass::execGRASS("g.list", type = "raster")


system("r.report map=above_95th_percentile units=c,p")
pixel_count <- execGRASS("r.stats", input = "above_95th_percentile", flags = c("n", "quiet"), intern = TRUE)
pixel_count


# Step 1: Convert the 90th percentile raster to points
execGRASS("r.to.vect", input="above_95th_percentile", output="percentile_points", type="point")


# Step 2: Run Voronoi tessellation on the points
execGRASS("v.voronoi", input="percentile_points", output="voronoi_polygons")

# Optional Step 3: Convert Voronoi polygons back to a raster
execGRASS("v.to.rast", input="voronoi_polygons", output="voronoi_raster", use="cat")

# Export Voronoi polygons to a shapefile

execGRASS("v.out.ogr", input="voronoi_polygons", output="voronoi_polygons.shp", format="ESRI_Shapefile")

voronoi_polygons <- st_read("voronoi_polygons.shp")


ggplot() +
  geom_sf(data = voronoi_polygons, fill = "lightblue", color = "black", lwd = 0.5) +
  theme_minimal() +
  labs(title = "Voronoi Polygons")




## Check rast back from GRASS to R (can be SLOW)
#raster_back <- read_RAST("pop", return_format = "terra") 




#subset_districts <- ind_districts[ind_districts$name_en %in% keep, ]
#sf::st_write(subset_districts, 'subset_districts.shp')

vector_file <- "C://Users//rdelaram//Documents//GitHub//eride/data//subset_districts.shp" 


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









