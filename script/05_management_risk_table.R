# Management layer and Pop at risk biv maps

require(terra)
require(rgrass)
require(rnaturalearth)
require(sf)
require(ggplot2)
library(dplyr)
#devtools::install_github("G-Thomson/Manu")
library(Manu)
library(ggraph)
library(tidygraph)
library(maps)
library(sfnetworks)
library(ggspatial)
library(exactextractr)
library(biscale)
library(cowplot)
library(here)
# Get management rast

lesiv <- 'D:/OneDrive - Massey University/hostland/data/lesiv_zenodo/FML_v3-2_with-colorbar.tif'

manrast <- rast(lesiv)
  
#plot(manrast)

vector_file <- "C://Users//rdelaram//Documents//GitHub//eride/data//subset_districts.shp" 
regions <- read_sf(vector_file)

regions

raster_layer_raster <- as(manrast, "Raster")

# Calculate lu management class pct cover

regions$area <- st_area(regions)

landcov_fracs <- exact_extract(raster_layer_raster, regions, function(df) {
  df %>%
    mutate(frac_total = coverage_fraction / sum(coverage_fraction)) %>%
    group_by(name, value) %>%
    summarize(freq = sum(frac_total), .groups = 'drop')  # Use .groups to drop unused groups
}, summarize_df = TRUE, include_cols = 'name', progress = FALSE)

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
  select(name, value, freq) %>%  
  group_by(name, value) %>%  
  summarize(freq = sum(freq, na.rm = TRUE), .groups = 'drop') %>%  # Summarize frequencies
  tidyr::pivot_wider(names_from = value, values_from = freq, values_fill = list(freq = 0)) %>%  # Pivot to wide format
  rename_with(~ paste0("manag_", .), -name)  # Add 'manag_' prefix to all columns except 'name'

rowSums(landcov_wide[1,2:6])

# get shape with management cover
regions_updated <- regions %>%
  left_join(landcov_wide, by = "name")


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
  ggplot(aes(x = name, y = freq, fill = Type_Specific)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip() +
  labs(title = "",
       x = "Region",
       y = "Proportion",
       fill = "Land cover type") +
  #scale_fill_manual(values = custom_palette) +  
  scale_fill_manual(values = rev(get_pal("Pohutukawa"))) +
  #scale_fill_grey()+
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = 'right')



## Open PAR file
setwd(here())
setwd('results')
regions_updated

st_write(regions_updated, "management_cover.shp", append=FALSE)

regions_PAR <- read_sf('regions_PAR.shp')

data.frame(regions_PAR[c('name', 'PAR')])

# Join
regions_updated_PAR <- regions_updated %>%
  left_join(data.frame(regions_PAR[c('name', 'PAR')]))

nrow(regions_updated_PAR)
regions_updated_PAR$manag_53

table_management_districts <- landcov_fracs %>%
  filter(!is.na(value)) %>%
  group_by(name) %>%
  arrange(desc(freq), .by_group = TRUE)


colnames(regions_updated_PAR)

# Scatterplot of variation in PAR according to management type
colnames(regions_updated_PAR)

manag_labels <- data.frame(
  manag_type = c("manag_11", "manag_20", "manag_31", "manag_32", "manag_40", "manag_53"),
  Type_Broad = c("No management", "Managed", "Managed", "Managed", "Managed", "Managed"),
  Type_Specific = c("No management", "Managed low-level", "Managed long time", "Managed short time", "Managed oil Palm", "Managed agroforestry")
)


landcov_long <- regions_updated_PAR %>%
      tidyr::pivot_longer(cols = c("manag_11", "manag_20", "manag_32", "manag_40", "manag_53"),
               names_to = "manag_type", values_to = "manag_value")

landcov_longl <- landcov_long %>%
  left_join(manag_labels, by = "manag_type")

colnames(landcov_longl)

landcov_longl$Type_Specific

# Create the scatterplot
fig_land_par <- landcov_longl %>% 
  filter(manag_type %in% c("manag_11", "manag_20", "manag_53")) %>% 
  ggplot(aes(x = manag_value, y = PAR, color = Type_Specific)) +
  geom_point(size=3) +
  geom_smooth(method = "lm", aes(group = Type_Specific, fill = Type_Specific), 
              formula = 'y ~ x', se = TRUE, size=1.6, show.legend = FALSE) +  
  labs(x = "% Land cover", y = "PAR", color = "Management type") +
  #scale_y_log10() + 
  scale_color_manual(values = get_pal("Pohutukawa")[c(4,3,2)]) +  
  scale_fill_manual(values = get_pal("Pohutukawa")[c(4,3,2)]) +  
  theme_minimal() +  
  theme(legend.position = "right")


fig_land_par

ggsave("Fig_S09A.png", fig_land_par, width = 8, height =4, dpi = 300)
ggsave("Fig_S09A.jpg", fig_land_par, width = 8, height =4, dpi = 300)



#------
require(ggridges)
par_joy <- landcov_longl %>%
  filter(manag_type %in% c("manag_11", "manag_20", "manag_53")) %>%  # Remove NA values
  ggplot(aes(x = manag_value, y = Type_Specific, fill = Type_Specific)) + 
  #facet_wrap(~ name, nrow = 1, scales = "fixed") + 
  geom_density_ridges(scale = 2, rel_min_height = 0.01, size = 0.8, show.legend = FALSE) +  # Ridge plot settings
  labs(x = "% Land cover", y = "Management type", fill = "Management type") +  # Update axis labels
  scale_fill_manual(values = get_pal("Pohutukawa")[c(4, 3, 2)]) +  # Apply the same palette
  geom_vline(xintercept = 0.3, linetype = "dashed", color = "gray50", size = 1) +  # Add dashed line at x = 0.3
  theme_minimal() +  
  theme(legend.position = "right")

par_joy

#export 

ggsave("Fig_04A.jpg", plot = par_joy, width = 10, height = 4, dpi = 300)

#--
# export tibble as df
#xlsx::write.xlsx2(data.frame(table_management_districts), sheetName='Table', 
#                  file = 'Table_management_districts.xlsx', row.names = FALSE)

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
  #geom_sf_text(data = data, aes(label = name), size = 3, color = "black") + 
  ggsflabel::geom_sf_label_repel(data = data, aes(label = name), size =2.5, color = "black", 
                                 show.legend = FALSE, alpha=0.7) +
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
  #geom_sf_text(data = data, aes(label = name), size = 3, color = "black") + 
  ggsflabel::geom_sf_label_repel(data = data, aes(label = name), size = 2.5, color = "black", 
                                 show.legend = FALSE,  alpha=0.7) +
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
setwd('Figures')
bivfigs_long

ggsave(filename = "Fig_S6.jpg", plot = bivfigs_long, width = 8, height = 8, dpi = 300)
ggsave(filename = "Fig_S6.tif", plot = bivfigs_long, width = 8, height = 8, dpi = 300)
#--------------------------------------