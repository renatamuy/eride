################################################################################
# Publication: Upscaling effects on infectious disease emergence risk emphasize 
# the need for local planning in primary prevention within biodiversity hotspots
# Script: Management layer and Pop at risk ggviolins - Map with ZOI
# Author: R. L. Muylaert
# Date: 2025
# R version 4.5.1
################################################################################

gc()

require(terra)
require(rgrass)
require(rnaturalearth)
require(sf)
require(ggplot2)
library(dplyr)
library(Manu)
library(ggraph)
library(tidygraph)
library(maps)
library(sfnetworks)
library(ggspatial)
library(exactextractr)
library(biscale)
library(cowplot)
require(here)
require(oneimpact)
library (rasterVis)
require(RColorBrewer)

# Get management rast

lesiv <- 'E:/manrast/manrast.tif'

manrast <- rast(lesiv)

par <- 'E:/eride_scales_z0p20/PAR_100.tif'

parr <- rast(par)

manrast_cropped <- crop(manrast, ext(parr))

# Resample keeping cat codes
manrast_cropped_aligned <- resample(manrast_cropped, parr, method='near')

parr_values <- as.data.frame(parr, xy = TRUE, na.rm = TRUE)
manrast_values <- as.data.frame(manrast_cropped_aligned, xy = TRUE, na.rm = TRUE)

merged_data <- left_join(parr_values, manrast_values, 
                         by = c("x", "y")) 

colnames(merged_data) <- c("x"   ,    "y"  ,     "PAR"  ,   "manag_type")

str(merged_data)


#----------------------

manag_labels <- data.frame(
  manag_type = c(11, 20, 31, 32, 40, 53),
  Type_Broad = c("No management", "Managed", "Managed", "Managed", "Managed", "Managed"),
  Type_Specific = c("No management", "Managed low-level", "Managed long time", "Managed short time", "Managed oil Palm", "Managed agroforestry")
)


merged_datal <- merged_data %>%
  left_join(manag_labels, by = "manag_type")

summary(merged_datal$PAR)

# Create the scatterplot
head(merged_datal)

#filter(!is.na(value)) %>%

fig_land_par <- merged_datal %>% 
  filter(manag_type %in% c("11", "20", "53")) %>% 
  ggplot(aes(x = as.factor(Type_Specific), y = PAR)) +
  geom_violin(aes(fill = as.factor(Type_Specific)), scale = "width", trim = FALSE) +
  scale_fill_manual(values = get_pal("Pohutukawa")[c(4,3,2)])+
  labs(title = "", x = "Forest management",  y = "PAR") +
  #scale_y_log10() + 
  theme_minimal() +
  theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1, size = 10)) 

fig_land_par

# Export 

setwd(here())
setwd('results/Figures')

ggsave("Fig_S10.png", fig_land_par, width = 4, height =4, dpi = 300)
ggsave("Fig_S10.tif", fig_land_par, width = 4, height =4, dpi = 300)

# ---------------- Cumulative risk ---
# Java island extent is: 1,064 km long per 140 kilometers wide

10000 # 10 km
100000 # 100 km
1000000 # 1000 km

zoi_values <- 100000# 100km 

# SLOW
risk_100km <- calc_zoi_cumulative(parr, type = "Gauss", radius = zoi_values)

# 55943916 cells
risk_100km

setwd('G:/')

output_file <- "risk_100km.tif"

writeRaster(risk_100km, output_file, overwrite = TRUE)

myPal <- rev(RColorBrewer::brewer.pal('Spectral', n=4))
selected_colours <- c("#5FA1F7", "#83A552","#9B1F1A")
selected_colours <- get_pal("Pohutukawa") #[c(1,2,3,4)]
myPal <- colorRampPalette(selected_colours)(100)
myTheme <- rasterTheme(region = myPal)

rasterVis::levelplot(risk_100km, par.settings = myTheme, main='Received risk (100 km)')

# Create df
risk_df <- as.data.frame(risk_100km, xy = TRUE, na.rm = TRUE)
head(risk_df)
nrow(risk_df)
colnames(risk_df) <- c('x', 'y', 'zoi_cumulative_100km' )

# Export
setwd(here())
setwd('results')
write.csv(risk_df, 'risk_df_1000km.csv', row.names = FALSE)

# Pixel-level based map 

zoi_map <- ggplot() +
  geom_tile(data = risk_df, aes(x = x, y = y, fill = zoi_cumulative_100km)) +
  coord_fixed(1.3) + 
  theme_minimal() +  
  theme_void() +
  labs(title = "Received Risk (1000 km)") +
  scale_fill_gradient(low= "#5FA1F7", high= "#9B1F1A") + 
  labs(fill='Cumulative Received Risk')+
  theme(plot.background = element_rect(fill = "azure2", color = NA)) #+
#annotation_north_arrow(location = "tr", which_north = "true", style = north_arrow_fancy_orienteering) +
#annotation_scale(location = "bl", width_hint = 0.5, unit_category = "metric", 
# style = "ticks", height = unit(0.3, "cm"), 
# plot_unit = c("km"), pad_x = unit(0.2, "cm")) #+  coord_sf(crs = 3857)

zoi_map


zoi_map_nolabs <- ggplot() +
  geom_tile(data = risk_df, aes(x = x, y = y, fill = zoi_cumulative_100km)) +
  coord_fixed(1.3) + 
  theme_minimal() +  
  theme_void() +
  labs(title = "") +
  scale_fill_gradient(low= "#5FA1F7", high= "#9B1F1A", 
  breaks = range(risk_df$zoi_cumulative_100km),
  labels = c("Low", "High")) + 
  labs(fill='')+
  theme(plot.background = element_rect(fill = "azure2", color = NA)) #+
#annotation_north_arrow(location = "tr", which_north = "true", style = north_arrow_fancy_orienteering) +
#annotation_scale(location = "bl", width_hint = 0.5, unit_category = "metric", 
# style = "ticks", height = unit(0.3, "cm"), 
# plot_unit = c("km"), pad_x = unit(0.2, "cm")) #+  coord_sf(crs = 3857)

zoi_map_nolabs

setwd(here())
setwd('results/Figures')

ggsave("Fig_04C.jpg", zoi_map_nolabs, width=18, height = 10, dpi = 300)
ggsave("Fig_04C.tif", zoi_map_nolabs, width=18, height = 10, dpi = 300)
#----------------------------------------------------------------------------------------------