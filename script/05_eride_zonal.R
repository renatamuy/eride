# java zonal

require(terra)
require(rgrass)
require(rnaturalearth)

#--------------------------------------------------------------------------------------------
# Provinces to keep
keep <- c("Banten",
          "West Java", 
          "Central Java",   
          "Yogyakarta"  ,
          "East Java" ,
          "Bali")
#subset_districts <- ind_districts[ind_districts$name_en %in% keep, ]
#sf::st_write(subset_districts, 'subset_districts.shp')

vector_file <- "C://Users//rdelaram//Documents//GitHub//eride/data//subset_districts.shp" 

#epsg 3857


#rgrass::execGRASS("g.list", type = "vector")
# Import the vector
rgrass::execGRASS(
  cmd = "v.import",
  flags = c("overwrite"),                       # Allow overwriting existing data
  input = vector_file,                          # Input vector file
  output = 'myzones')

rgrass::execGRASS("g.list", type = "vector")

# Set parameters
vector_name <- "myzones"                   # Name of the input vector map
output_raster_name <- "myzonesr"      # Desired name for the output raster
column_name <- "name_en"                    # Column to use for raster values

# Convert vector to raster
rgrass::execGRASS(
  cmd = "v.to.rast",
  flags = c("overwrite"),                   # Allow overwriting existing raster
  input = vector_name,                      # Input vector map
  output = output_raster_name,              # Output raster name
  use = "cat",                            # Use attribute from the vector
  layer = column_name,
  label_column = column_name)

rgrass::execGRASS("g.list", type = "raster")

myzonesr

rgrass::execGRASS(
  cmd = "r.import",
  flags = c("overwrite"),                       # Allow overwriting existing data
  input = 'myzonesr',                          # Input vector file
  output = 'myzonesr')


rgrass::execGRASS("r.out.gdal",
                  input="myzonesr",
                  output="myzonesr.tif",
                  format="GTiff",
                  type="Byte",
                  flags="overwrite")

myzonesr_import <- rast('myzonesr.tif')

plot(myzonesr_import)


# Run zonal statistics

# Set parameters
raster_name <- "PAR"                         # Base raster map for statistics
zones_name <- "myzonesr"                      # Zones vector map for statistics
output_name <- "zonal_output"                # Name for the output raster
method <- "average"                          # Method for zonal statistics

# Run zonal statistics
rgrass::execGRASS(
  cmd = "r.stats.zonal",
  flags = c("overwrite"),                    # Allow overwriting existing data
  base = raster_name,                        # Input raster map for statistics
  cover = zones_name,                    # Zones defined by the vector
  method = method,                           # Method for statistics (e.g., average)
  output = output_name   # Output name for the statistics
)

#---------------------------------------------------
