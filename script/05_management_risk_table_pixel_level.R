# Management layer and Pop at risk ggviolins
# Map with ZOI
# Renata Mulaert 
#----------------------------------------------

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

# Get management rast

lesiv <- 'E:/manrast/manrast.tif'

manrast <- rast(lesiv)

par <- 'E:/PAR_100.tif'

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
  scale_y_log10() + 
  theme_minimal() +
  theme(legend.position = "none", axis.text.x = element_text(angle = 45, hjust = 1, size = 10)) 

fig_land_par

# Save
ggsave("fig_land_par_pixel_log.png", fig_land_par, width = 4, height =4, dpi = 300)
ggsave("fig_land_par_pixel_log.jpg", fig_land_par, width = 4, height =4, dpi = 300)

# ---------------- Cumulative risk

require(oneimpact)
library (rasterVis)
require(RColorBrewer)

# Java island extent is: 1,064 km

1000 * 10 # 10 km
1000 * 100 # 100 km
1000 * 1000 # 100 km

# 55943916 cells
zoi_values <- c(1000 * 1000)

risk_1km <- calc_zoi_cumulative(parr, type = "Gauss", radius = zoi_values)

names(risk_1km)

myPal <- rev(RColorBrewer::brewer.pal('Spectral', n=4))

selected_colours <- c("#5FA1F7", "#83A552","#9B1F1A")
selected_colours <- get_pal("Pohutukawa") #[c(1,2,3,4)]
myPal <- colorRampPalette(selected_colours)(100)
myTheme <- rasterTheme(region = myPal)

rasterVis::levelplot(risk_1km, par.settings = myTheme, main='Received risk (100 km)')

risk_df <- as.data.frame(risk_1km, xy = TRUE, na.rm = TRUE)

head(risk_df)
nrow(risk_df)

colnames(risk_df) <- c('x', 'y', 'zoi_cumulative_1000km' )

write.csv(risk_df, 'risk_df_1000km.csv', row.names = FALSE)

# map 

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
# plot_unit = c("km"), pad_x = unit(0.2, "cm")) #+  coord_sf(crs = 4326)

zoi_map

ggsave("fig_zoi_pixel_1000km.jpg", zoi_map, width = 4, height =4, dpi = 300)

#----------------------------------------------------------------------------------------------