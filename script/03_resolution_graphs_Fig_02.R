################################################################################
# Publication: Upscaling effects on infectious disease emergence risk emphasize 
# the need for local planning in primary prevention within biodiversity hotspots
# Script: Resolution upscale effects - from 100 m to 5000 km
# Author: R. L. Muylaert
# Date: 2025
# R version 4.5.1
################################################################################

library(terra)  
library(ggplot2) 
library(dplyr) 
library(tidyr)  
library(viridis)
require(here)

setwd('E://eride_scales_z0p20')

# Define the working resolutions
# 11_scales
#resolutions <- c(100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 5000)
resolutions <- c(100, 150, 200, 250, 300, 350, 400, 500, 600, 700, 800, 900, 1000, 2000, 2500, 3000, 4000, 5000)
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
 
# From 18 milion to 12k!
res_ncell <- table(data_df$Resolution)

res_ncelldf <- data.frame(res_ncell)

colnames(res_ncelldf) <- c('Resolution','N')

res_ncelldf

# Factorise
data_df$Resolution <- factor(data_df$Resolution, levels = resolutions)

# Plotting annotation on N and Resolution

res_ncelldf$Resolution <- as.numeric(as.character(res_ncelldf$Resolution))
str(res_ncelldf)

# X lab
cuslab <- paste0(res_ncelldf$Resolution, ' m ', '\n', '(N=',  res_ncelldf$N, ')')
cuslab

# Plot 
my_plotn <- ggplot(data_df, aes(x = as.factor(Resolution), y = Value)) +
  geom_violin(aes(fill = as.factor(Resolution)), scale = "width", trim = FALSE) +
  scale_fill_viridis(discrete = TRUE) +  
  facet_wrap(~ Metric, scales = "free_y") +
  labs(title = "", x = "Resolution",  y = "Value") +
  theme_minimal() +
  theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1, size = 8)) +
  scale_x_discrete(labels = cuslab)

my_plotn

# Export
setwd(here())
setwd('results//Figures/')

ggsave("Fig_02.jpg", plot = my_plotn, width = 12, height = 6, dpi = 300)
ggsave("Fig_02.tif", plot = my_plotn, width = 12, height = 6, dpi = 300)

head(data_df)


df_summary <- data_df %>%
  group_by(Metric, Resolution) %>%
  summarise(
    Mean_Value = mean(Value, na.rm = TRUE),
    SD_Value = sd(Value, na.rm = TRUE),  # Calculate standard deviation
    .groups = 'drop'
  )


df_summary

pixel_info <- data.frame(Resolution = factor(resolutions), cost= res_ncelldf$N )

str(pixel_info)

infodf <- left_join(df_summary, pixel_info, by='Resolution' ) %>% 
  filter(Metric=='eRIDE')

#plot( infodf$SD_Value ~ infodf$cost, pch=19, cex=3, xlab='Pixel Cost', ylab=' SD Information (eRIDE)')
#text(infodf$SD_Value ~ infodf$cost, labels = scale, pos = 4, col='firebrick', offset = 0.7)

getthis <- which(infodf[,'Resolution'] == 100)

infodf$SD_loss <- as.numeric(infodf[getthis, 'SD_Value'] ) - infodf$SD_Value

infodf$Mean_loss <- as.numeric(infodf[getthis, 'Mean_Value'] ) - infodf$Mean_Value

infodf$SD_loss_pct <- 100 -  100* (infodf$SD_Value / as.numeric(infodf[getthis, 'SD_Value']))

infodf$Mean_loss_pct <- 100 -  100* (infodf$Mean_Value / as.numeric(infodf[getthis, 'Mean_Value']))

infodf$SD_retained_pct <- 100* (infodf$SD_Value / as.numeric(infodf[getthis, 'SD_Value']))

infodf$Mean_retained_pct <-  100* (infodf$Mean_Value / as.numeric(infodf[getthis, 'Mean_Value']))

infodf

# Export 
setwd(here())
setwd('results')

write.table(file='resolution_effect_eride.txt', infodf, row.names = FALSE)

# Repeat for PAR

infodf_PAR <- left_join(df_summary, pixel_info, by='Resolution' ) %>% 
  filter(Metric=='PAR')

infodf_PAR

getthispar <- which(infodf_PAR[,'Resolution'] == 100)

infodf_PAR$SD_loss <- as.numeric(infodf_PAR[getthispar, 'SD_Value'] ) - infodf_PAR$SD_Value

infodf_PAR$Mean_loss <- as.numeric(infodf_PAR[getthispar, 'Mean_Value'] ) - infodf_PAR$Mean_Value

infodf_PAR$SD_loss_pct <- 100 -  100* (infodf_PAR$SD_Value / as.numeric(infodf_PAR[getthispar, 'SD_Value']))

infodf_PAR$Mean_loss_pct <- 100 -  100* (infodf_PAR$Mean_Value / as.numeric(infodf_PAR[getthispar, 'Mean_Value']))

infodf_PAR$SD_retained_pct <- 100* (infodf_PAR$SD_Value / as.numeric(infodf_PAR[getthispar, 'SD_Value'])  )

infodf_PAR$Mean_retained_pct <-  100* (infodf_PAR$Mean_Value / as.numeric(infodf_PAR[getthispar, 'Mean_Value']))

infodf_PAR

# Export
write.table(file='resolution_effect_par.txt', infodf_PAR, row.names = FALSE)

info_loss_plot_PAR <- ggplot(infodf_PAR, aes(x = cost, y = SD_loss)) +
  geom_point(size = 5, shape = 19) + 
  ggrepel::geom_text_repel(aes(label = Resolution),  
                           color = 'firebrick',
                           nudge_x = 0.1,  
                           nudge_y = 0.1, 
                           box.padding = 0.2, 
                           point.padding = 0.2,  
                           segment.color = 'grey50') + 
  geom_smooth(method = "gam", formula = y ~ s(x, k = 4), color = "gray50", se = FALSE, linetype = "dashed") +  # Add GAM curve with k=4
  labs(x = 'Pixel Cost', y = 'SD Information Loss (PAR)') +  
  theme_bw() 

info_loss_plot_PAR

# Export
#ggsave("scale_effect_SD_PAR.jpg", plot = info_loss_plot_PAR, width = 8, height = 6, dpi = 300)
#ggsave("scale_effect_SD_PAR.png", plot = info_loss_plot_PAR, width = 8, height = 6, dpi = 300)
#---------------------------------------------------