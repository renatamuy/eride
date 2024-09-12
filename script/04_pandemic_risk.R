# Load necessary libraries

library(raster)
library(leastcostpath)
library(igraph)
library(sf)

source('simulate_raster.R')
source('create_cost_surface.R')


# Set raster dimensions
nrows <- 100
ncols <- 100

# Define the extent of the raster (xmin, xmax, ymin, ymax)
extent_r <- extent(0, ncols, 0, nrows)


# Simulate the rasters

ref_crs <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0" 


# Simulate a aggregated spillover risk raster (values between 0 and 4)
spillover_risk <- simulate_aggregated_raster(nrows, ncols, c(0, 4), "simulated_spillover_risk_aggregated.tif")

# Plot the raster
plot(spillover_risk, main = "Aggregated Spillover Risk Raster")
crs(spillover_risk) <-ref_crs

# Population at risk raster (values between 100 and 1000)
population_at_risk <- simulate_raster(nrows, ncols, c(100, 6000), "simulated_population_at_risk.tif")
crs(population_at_risk) <- ref_crs

# Population density raster (values between 1000 and 10000)
population <- simulate_aggregated_raster(nrows, ncols, c(1, 30000), "simulated_population.tif")
crs(population) <- ref_crs

any(is.na(values(population)))  # Check for NA values in population raster
any(is.nan(values(population))) # Check for NaN values in population raster

# Plot the rasters
plot(spillover_risk, main = "Spillover Risk Raster")
plot(population_at_risk, main = "Population at Risk Raster")
plot(population, main = "Population Density Raster")

# Load the raster data

#spillover_risk <- raster("path_to_spillover_risk.tif")  # Spillover risk raster
#population_at_risk <- raster("path_to_population_at_risk.tif")  # Population at risk raster
#population <- raster("path_to_population.tif")  # Population density raster

# raster not rast

cost_surface <- create_cost_surface(population)

plot(cost_surface)

#
names(spillover_risk) <- "SpilloverRisk"
names(cost_surface) <- "CostSurface"
#


# useful ---------------------------
#spillover_points <- which(!is.na(values(spillover_risk)) & !is.nan(values(spillover_risk)))
#src_coords <- xyFromCell(spillover_risk, spillover_points[i])
#src_coords_sf <- st_as_sf(data.frame(src_coords), coords = c("x", "y"), crs = ref_crs)
# as_Spatial to come back from sf to spatialpointsdf
# Remove nans: 
#spillover_points <- which(!is.na(values(spillover_risk)) & !is.nan(values(spillover_risk)))



#--- Get central coords for simulation

# Calculate the center coordinates
center_row <- round(nrows / 2)
center_col <- round(ncols / 2)

# Define the bounding box around the center (for example, a 5x5 box)
row_min <- max(center_row - 2, 1)
row_max <- min(center_row + 2, nrows)
col_min <- max(center_col - 2, 1)
col_max <- min(center_col + 2, ncols)

# Get indices of points in the bounding box
bounding_box_indices <- cellFromRowCol(spillover_risk, row_min:row_max, col_min:col_max)

# Get valid spillover points from the bounding box
valid_points <- which(!is.na(values(spillover_risk)[bounding_box_indices]) & 
                        !is.nan(values(spillover_risk)[bounding_box_indices]))

# Select up to 10 points randomly from the valid points in the bounding box
set.seed(123)  # for reproducibility
spillover_points_middle <- sample(valid_points, min(10, length(valid_points)))

# Convert to coordinates (optional)
coords_middle <- xyFromCell(spillover_risk, spillover_points_middle)

# Print the coordinates
print(coords_middle)

dest_coords_sf <- st_as_sf(data.frame(coords_middle), coords = c("x", "y"), crs = ref_crs)

#Create cost surface

# Create pandemic_spread
#pandemic_risk_map <- pandemic_spread(spillover_risk, cost_surface)

# Visualize the resulting pandemic risk map
plot(pandemic_risk_map, main = "Pandemic Risk Map")

# Step 4: Assess influence of source pixels (those with high populations at risk)
influence <- population_at_risk * pandemic_risk_map

# Visualize the resulting pandemic risk map
plot(pandemic_risk_map, main = "Pandemic Risk Map")

