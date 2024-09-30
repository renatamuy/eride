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

require(sf)

regions <- read_sf(vector_file)

centroids <- st_centroid(myshaprefile)

regions


#- 
raster_data <- terra::rast("E://eride_optimized//eRIDE.tif")

# Extract mean raster values (e.g., GDP) for each region
regions$PAR <- terra::extract(raster_data, regions, fun = mean, na.rm = TRUE)


# Step 4: Calculate pairwise distances between centroids of regions
n_regions <- nrow(regions)

# Initialize an empty matrix for distances
distance_matrix <- matrix(NA, n_regions, n_regions)

# Loop through each pair of regions and calculate the distance between their centroids
for (i in 1:n_regions) {
  for (j in 1:n_regions) {
    if (i != j) {
      # Calculate geographic distance (in kilometers) between centroids
      distance_matrix[i, j] <- distGeo(st_coordinates(centroids[i,]), st_coordinates(centroids[j,])) / 1000
    } else {
      distance_matrix[i, j] <- 0 # Distance to self is 0
    }
  }
}

# Step 5: Create a data frame to store pairwise region interactions
gravity_data <- data.frame()

# Populate the dataframe with region pairs, their PARs (pop at risk), and distances
for (i in 1:n_regions) {
  for (j in 1:n_regions) {
    if (i != j) {  # Exclude self-pairs
      gravity_data <- rbind(gravity_data, data.frame(
        Region_A = regions$RegionName[i],  # Replace 'RegionName' with the name column in your shapefile
        Region_B = regions$RegionName[j],
        GDP_A = regions$PAR[i],
        GDP_B = regions$PAR[j],
        Distance = distance_matrix[i, j]
      ))
    }
  }
}

# Step 6: Apply the gravity model formula
# Define a constant G (you can modify this as needed)
G <- 1

# Calculate trade flow using the gravity model formula
gravity_data$Risk_Flow <- G * (gravity_data$PAR_A * gravity_data$PAR) / gravity_data$Distance

# View the results
head(gravity_data)


#-------------------------------------------















# Grass workflow
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
