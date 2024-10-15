# Management layer and Pop at risk biv maps
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

# Get management rast

lesiv <- 'D:/OneDrive - Massey University/hostland/data/lesiv_zenodo/FML_v3-2_with-colorbar.tif'

manrast <- rast(lesiv)
  
# Get shapefile of a subset districts (optional)

keep <- c("Banten",
          "West Java", 
          "Central Java",   
          "Yogyakarta"  ,
          "East Java", "Bali"      ) # 

#subset_districts <- ind_districts[ind_districts$name_en %in% keep, ]
#sf::st_write(subset_districts, 'subset_districts.shp')

vector_file <- "C://Users//rdelaram//Documents//GitHub//eride/results//regions_voronoi_forced_PAR.shp" 
regions <- read_sf(vector_file)
#regions <- regions[regions$name_x %in% keep, ] # Be aware of change in cols here

regions

raster_layer_raster <- as(manrast, "Raster")

# Calculate lu management class pct cover

regions$voronoi_id
regions$area <- st_area(regions)

landcov_fracs <- exact_extract(raster_layer_raster, regions, function(df) {
  df %>%
    mutate(frac_total = coverage_fraction / sum(coverage_fraction)) %>%
    group_by(voronoi_id, value) %>%
    summarize(freq = sum(frac_total), .groups = 'drop')  # Use .groups to drop unused groups
}, summarize_df = TRUE, include_cols = 'voronoi_id', progress = FALSE)

landcov_fracs

# Plots

land_cover_lookup <- data.frame(
  value = c(11, 20, 31, 32, 40, 53),
  Type_Broad = c("No management", "Managed", "Managed", "Managed", "Managed", "Managed"),
  Type_Specific = c("No management", "Managed low-level", "Managed long time", "Managed short time", "Managed oil Palm", "Managed agroforestry")
)

# Assuming 'landcov_fracs' is your dataframe with the columns: name, value, and freq
landcov_fracs <- landcov_fracs %>%
  left_join(land_cover_lookup, by = "value")

head(landcov_fracs)

landcov_wide <- landcov_fracs %>%
  select(voronoi_id, value, freq) %>%  
  group_by(voronoi_id, value) %>%  
  summarize(freq = sum(freq, na.rm = TRUE), .groups = 'drop') %>%  # Summarize frequencies
  tidyr::pivot_wider(names_from = value, values_from = freq, values_fill = list(freq = 0)) %>%  # Pivot to wide format
  rename_with(~ paste0("manag_", .), -voronoi_id)  # Add 'manag_' prefix to all columns except 'name'

rowSums(landcov_wide[1,2:6])

# get shape with management cover
regions_updated <- regions %>%
  left_join(landcov_wide, by = "voronoi_id")


ggplot(data = regions_updated) +
  geom_sf(aes(fill = manag_11), color = NA) +  
  scale_fill_viridis_c(option = "viridis", name = "Non-Managed Area") +  # Use viridis color scale
  labs(title = "Land Cover by Management Type",
       subtitle = "Distribution of Non-Managed Area",
       x = "Longitude",
       y = "Latitude") +
  theme_minimal() +
  theme(legend.position = "right") 

# -------------
head(regions_updated$manag_11)

# General map for exploration

ggplot(data = regions_updated) +
  geom_sf(aes(fill = manag_11), color = NA) +  
  scale_fill_viridis_c(option = "viridis", name = "Non-Managed Area") +
  labs(title = "Land Cover by Management Type",
       subtitle = "Distribution of Non-Managed Area",
       x = "Longitude",
       y = "Latitude") +
  theme_minimal() +
  theme(legend.position = "right") 


custom_palette <- c(
  "No management" = "snow2",         
  "Managed low-level" = "snow3",     
  "Managed long time" = "#8c564b",     
  "Managed short time" = "salmon",    
  "Managed oil Palm" = "firebrick",       
  "Managed agroforestry" = "lightskyblue"    
)


# Create the bar plot with the manual palette
landcov_fracs %>%
  filter(!is.na(value)) %>%
  ggplot(aes(x = voronoi_id, y = freq, fill = Type_Specific)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "",
       x = "Region",
       y = "Proportion",
       fill = "Land cover type") +
  #scale_fill_manual(values = custom_palette) +  
  #scale_fill_manual(values = rev(get_pal("Kotare"))) +
  scale_fill_grey()+
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = 'right')


## Open PAR file
setwd('results')
regions_updated
st_write(regions_updated, "management_cover_voronoi.shp", append=FALSE)

#-----------------

regions_PAR <- read_sf('regions_voronoi_forced_PAR.shp')

data.frame(regions_PAR[c('voronoi_id', 'PAR')])

# Join
regions_updated_PAR <- regions_updated %>%
  left_join(data.frame(regions_PAR[c('voronoi_id', 'PAR')]))

nrow(regions_updated_PAR)
regions_updated_PAR$manag_53


library(biscale)
library(cowplot)
# A 
data <- bi_class(regions_updated_PAR, x = PAR, y = manag_11, style = "quantile", dim = 3)

data

map <- ggplot() +
  geom_sf(data = data, mapping = aes(fill = bi_class), color = "white", size = 0.1, show.legend = FALSE) +
  bi_scale_fill(pal = "GrPink", dim = 3) +
  labs(
    title = "",
    subtitle = "A."
  ) +
  #geom_sf_text(data = data, aes(label = voronoi_id), size = 1, color = "black") + 
  ggsflabel::geom_sf_label_repel(data = data, aes(label = voronoi_id), size = 2, color = "black", 
                     show.legend = FALSE) +
  bi_theme( axis.title.x = element_blank(),  
            axis.title.y = element_blank(),  
            axis.text.x = element_blank(),    
            axis.text.y = element_blank()          )
map

legend <- bi_legend(pal = "GrPink",
                    dim = 3,
                    xlab = " Pop. at risk ",
                    ylab = " % Non-managed forest ",
                    size = 8)

bivfig <- cowplot::ggdraw() +
  draw_plot(map, 0, 0, 1, 1) +
  draw_plot(legend, 0.2, .65, 0.2, 0.2)


# B
data <- bi_class(regions_updated_PAR, x = PAR, y = manag_53, style = "quantile", dim = 3)


mapb <- ggplot() +
  geom_sf(data = data, mapping = aes(fill = bi_class), color = "white", size = 0.1, show.legend = FALSE) +
  bi_scale_fill(pal = "GrPink", dim = 3) +
  labs(
    title = "",
    subtitle = "B."
  ) +
  #geom_sf_text(data = data, aes(label = voronoi_id), size = 1, color = "black") + 
  ggsflabel::geom_sf_label_repel(data = data, aes(label = voronoi_id), size = 2, color = "black", 
                                 show.legend = FALSE) +
  bi_theme( axis.title.x = element_blank(),  
            axis.title.y = element_blank(),  
            axis.text.x = element_blank(),    
            axis.text.y = element_blank()          )

mapb

legendb <- bi_legend(pal = "GrPink",
                    dim = 3,
                    xlab = " Pop. at risk ",
                    ylab = " % Managed forest ",
                    size = 8)

bivfigs_long <- cowplot::ggdraw() +
  draw_plot(legend, 0, 0.55, 0.2, 0.45) +    # Legend on the left, occupying 20% width and 45% height
  draw_plot(map, 0.2, 0.55, 0.8, 0.45) +     # Map on the right, taking 80% width
  draw_plot(legendb, 0, 0.1, 0.2, 0.45) +    # Legendb on the left, same size as above
  draw_plot(mapb, 0.2, 0.1, 0.8, 0.45)       # Mapb on the right, same size as above

# export 

bivfigs_long

ggsave(filename = "fig_risk_management_long_voronoi_sflab.jpg", plot = bivfigs_long, width = 8, height = 8, dpi = 300)

ggsave(filename = "fig_risk_management_long_voronoi_sflab.tif", plot = bivfigs_long, width = 8, height = 8, dpi = 300)

#--------------------------------------