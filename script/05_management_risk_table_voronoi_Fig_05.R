# Management layer and Pop at risk biv maps
# 
#--------------------------------------------------------------

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
library(here)

# Get management raster
lesiv <- 'D:/OneDrive - Massey University/hostland/data/lesiv_zenodo/FML_v3-2_with-colorbar.tif'

manrast <- rast(lesiv)
  
# Open voronoi
vector_file <- "C://Users//rdelaram//Documents//GitHub//eride/results//regions_voronoi_forced_PAR.shp" 

regions <- read_sf(vector_file)

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

# exploration

ggplot(data = regions_updated) +
  geom_sf(aes(fill = manag_11), color = NA) +  
  scale_fill_viridis_c(option = "viridis", name = "Non-Managed Area") +
  labs(title = "Land Cover by Management Type",
       subtitle = "Distribution of Non-Managed Area",
       x = "Longitude",
       y = "Latitude") +
  theme_minimal() +
  theme(legend.position = "right") 


# bar plot
landcov_fracs <- landcov_fracs %>%
  mutate(name = factor(stringr::str_extract(voronoi_id, "^[^_]+")) )

# Figure S8
  
landcov_fracs %>%
  filter(!is.na(value)) %>%
  ggplot(aes(x = name, y = freq, fill = Type_Specific)) +
  geom_bar(stat = "identity", position = "dodge") +
  coord_flip()+
  #facet_wrap(~Type_Broad  ) +
  labs(title = "",
       x = "Region",
       y = "Proportion",
       fill = "Land cover type") +
  scale_fill_manual(values = rev(get_pal("Pohutukawa")) ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = 'right')


# Open PAR file
setwd(here())
setwd('results')
st_write(regions_updated, "management_cover_voronoi.shp", append=FALSE)

#-----------------

regions_PAR <- read_sf('regions_voronoi_forced_PAR.shp')

data.frame(regions_PAR[c('voronoi_id', 'PAR')])

# Join
regions_updated_PAR <- regions_updated %>%
  left_join(data.frame(regions_PAR[c('voronoi_id', 'PAR')]))


# after creating regions_updated_PAR
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

fig_land_par_gam <- landcov_longl %>% 
  filter(manag_type %in% c("manag_11", "manag_20", "manag_53")) %>% 
  ggplot(aes(x = manag_value, y = PAR, color = Type_Specific)) +
  geom_point(size=3) +
  #facet_wrap(~Type_Specific)+
  geom_smooth(method= 'gam', aes(group = Type_Specific, fill = Type_Specific), 
              formula = y ~ s(x, bs = "cs", fx = TRUE, k = 3),
              se = TRUE, size=1.6, show.legend = FALSE) +
  labs(x = "% Land cover", y = "PAR", color = "Management type") +
  scale_color_manual(values = get_pal("Pohutukawa")[c(4,3,2)]) +
  scale_fill_manual(values = get_pal("Pohutukawa")[c(4,3,2)]) +
  scale_y_log10() + 
  theme_minimal() +  theme(legend.position = "right") 

fig_land_par_gam

# Save
#ggsave("fig_land_par_voronoi_gam_col_log.png", fig_land_par_gam, width = 8, height =4, dpi = 300)
#ggsave("fig_land_par_voronoi_gam_col_log.jpg", fig_land_par_gam, width = 8, height =4, dpi = 300)


fig_land_par_glm <- landcov_longl %>% 
  filter(manag_type %in% c("manag_11", "manag_20", "manag_53")) %>% 
  ggplot(aes(x = manag_value, y = PAR, color = Type_Specific)) +
  geom_point(size=3) +
  #facet_wrap(~Type_Specific)+
  geom_smooth(method= 'glm', aes(group = Type_Specific, fill = Type_Specific), 
              se = TRUE, size=1.6, show.legend = FALSE) +
  labs(x = "% Land cover", y = "PAR", color = "Management type") +
  scale_color_manual(values = get_pal("Pohutukawa")[c(4,3,2)]) +
  scale_fill_manual(values = get_pal("Pohutukawa")[c(4,3,2)]) +
  scale_y_log10() + 
  theme_minimal() +  theme(legend.position = "right") 

fig_land_par_glm

# Save
setwd(here())
setwd('results/Figures')
ggsave("Fig_S10B.png", fig_land_par_glm, width = 8, height =4, dpi = 300)
ggsave("Fig_S10B.jpg", fig_land_par_glm, width = 8, height =4, dpi = 300)


# joyplot -----------------------------------
library(ggridges)
summary(landcov_longl$PAR)


mean_par <- mean(landcov_longl$PAR, na.rm = TRUE)

# Create new column "PAR_above_below"
landcov_longl <- landcov_longl %>%
  mutate(PAR_above_below = ifelse(PAR > mean_par, "high PAR", "low PAR"))


sd_par <- sd(landcov_longl$PAR, na.rm = TRUE)

thresholds <- c(mean_par - sd_par, mean_par, mean_par + sd_par)

# Create new column "PAR_category"
landcov_longl <- landcov_longl %>%
  mutate(PAR_category = case_when(
    PAR <= thresholds[1] ~ "very low PAR",
    PAR > thresholds[1] & PAR <= thresholds[2] ~ "low PAR",
    PAR > thresholds[2] & PAR <= thresholds[3] ~ "high PAR",
    PAR > thresholds[3] ~ "very high PAR"
  ))

landcov_longl <- landcov_longl %>%
  mutate(PAR_category = factor(PAR_category, 
                               levels = c("very low PAR", "low PAR", "high PAR", "very high PAR")))


#------
par_joy <- landcov_longl %>%
  filter(manag_type %in% c("manag_11", "manag_20", "manag_53"), !is.na(PAR_category)) %>%  # Remove NA values
  ggplot(aes(x = manag_value, y = Type_Specific, fill = Type_Specific)) + 
  facet_wrap(~ PAR_category, nrow = 1, scales = "fixed") + 
  geom_density_ridges(scale = 2, rel_min_height = 0.01, size = 0.8, show.legend = FALSE) +  # Ridge plot settings
  labs(x = "% Land cover", y = "Management type", fill = "Management type") +  # Update axis labels
  scale_fill_manual(values = get_pal("Pohutukawa")[c(4, 3, 2)]) +  # Apply the same palette
  geom_vline(xintercept = 0.3, linetype = "dashed", color = "gray50", size = 1) +  # Add dashed line at x = 0.3
  theme_minimal() +  
  theme(legend.position = "right")

par_joy

#export Fig 05
ggsave("Fig_05.jpg", plot = par_joy, width = 10, height = 3, dpi = 300)
ggsave("Fig_05.tif", plot = par_joy, width = 10, height = 3, dpi = 300)


# Checking
unique(regions_updated_PAR$name_x)

# Supplements A 
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
  ggsflabel::geom_sf_label_repel(data = data, 
                                 aes(label = voronoi_id), size = 1, color = "black", 
                     show.legend = FALSE, max.overlaps=33, alpha = 0.7) +
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
  ggsflabel::geom_sf_label_repel(data = data, aes(label = voronoi_id), 
                                 size = 1, color = "black", 
                                 show.legend = FALSE, max.overlaps=33,  alpha = 0.7) +
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

ggsave(filename = "Fig_S8.jpg", plot = bivfigs_long, width = 8, height = 8, dpi = 300)
ggsave(filename = "Fig_S8.tif", plot = bivfigs_long, width = 8, height = 8, dpi = 300)

#--------------------------------------