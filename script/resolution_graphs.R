# Required libraries
library(terra)  # For reading and working with raster data
library(ggplot2)  # For creating graphs
library(dplyr)  # For data manipulation
library(tidyr)  # For data reshaping

setwd('data')
# Define the working resolutions
resolutions <- c(30, 60, 100)

# Initialize an empty data frame to store the results
data_df <- data.frame(Resolution = integer(), Metric = character(), Value = numeric(), stringsAsFactors = FALSE)

# Function to read the raster data and store the values in long format
gather_values <- function(resolution) {
  # Define the file paths for each resolution
  eRIDE_path <- paste0("eRIDE_", resolution, ".tif")
  PAR_path <- paste0("PAR_", resolution, ".tif")
  
  # Read the rasters
  eRIDE_raster <- rast(eRIDE_path)
  PAR_raster <- rast(PAR_path)
  
  # Get the values for both rasters, removing NA values
  eRIDE_values <- values(eRIDE_raster, na.rm = TRUE)
  PAR_values <- values(PAR_raster, na.rm = TRUE)
  
  # Create data frames with values and associated metric
  eRIDE_df <- data.frame(Resolution = resolution, Metric = "eRIDE", Value = eRIDE_values)
  PAR_df <- data.frame(Resolution = resolution, Metric = "PAR", Value = PAR_values)
  
  # Ensure both data frames have the same structure (column names)
  colnames(eRIDE_df) <- colnames(PAR_df) <- c("Resolution", "Metric", "Value")
  
  # Combine the data frames
  combined_df <- rbind(eRIDE_df, PAR_df)
  
  return(combined_df)
}

# Loop through each resolution and gather values
for (res in resolutions) {
  data_df <- rbind(data_df, gather_values(res))
}

# Convert 'Resolution' to a factor for better ordering in the plot
data_df$Resolution <- factor(data_df$Resolution, levels = resolutions)

# Plot the violin plots using ggplot2
ggplot(data_df, aes(x = Resolution, y = Value)) +
  geom_violin(aes(fill = Resolution), scale = "width", trim = FALSE) +
  facet_wrap(~ Metric, scales = "free_y") +
  labs(title = "Distribution of eRIDE and PAR Values Across Resolutions",
       x = "Resolution (meters)",
       y = "Value") +
  theme_minimal() +
  theme(legend.position = "none")  # Hide legend for Resolution
