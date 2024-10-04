# Required libraries
library(terra)  # For reading and working with raster data
library(ggplot2)  # For creating graphs
library(dplyr)  # For data manipulation
library(tidyr)  # For data reshaping
#----------------------

setwd('E://')
# Define the working resolutions
resolutions <- c(100, 200, 300, 400, 500, 1000, 2000, 5000)

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
  
  # Ensure both data frames have the same structure
  colnames(eRIDE_df) <- colnames(PAR_df) <- c("Resolution", "Metric", "Value")
  
  # Combine the data frames
  combined_df <- rbind(eRIDE_df, PAR_df)
  
  return(combined_df)
}

# gather_values for all rasters

for (res in resolutions) {
  data_df <- rbind(data_df, gather_values(res))
}

tail(data_df)
str(data_df$Metric)
table(data_df$Resolution)

# Convert 'Resolution' to a factor for better ordering in the plot

data_df$Resolution <- factor(data_df$Resolution, levels = resolutions)

library(viridis)

# Plot the violin plots using ggplot2 with a viridis color palette
my_plot <- ggplot(data_df, aes(x = as.factor(Resolution), y = Value)) +
  geom_violin(aes(fill = as.factor(Resolution)), scale = "width", trim = FALSE) +
  scale_fill_viridis(discrete = TRUE) +  # Use the viridis color palette
  facet_wrap(~ Metric, scales = "free_y") +
  labs(title = "",
       x = "Resolution (meters)",
       y = "Value") +
  theme_minimal() +
  theme(legend.position = "none")  # Hide legend for Resolution


# Export
setwd('C://Users//rdelaram//Documents//GitHub//eride//results//')

ggsave("scale_effect.tif", plot = my_plot, width = 12, height = 5, dpi = 300)

#---------------------------------------------------