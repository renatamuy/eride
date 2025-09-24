################################################################################
# Publication: Upscaling effects on infectious disease emergence risk emphasize 
# the need for local planning in primary prevention within biodiversity hotspots
# Script: Voronoi tesselation in grass for delimiting high-pop centres
# Author: R. L. Muylaert
# Date: 2025
# R version 4.5.1
################################################################################

# Renata Muylaert 2024

require(rgrass)
require(terra)
require(sf)
require(here)

#setwd('C://Users//rdelaram//Documents//GitHub//eride//data//')
# Find a spacious dir
setwd('G:/')

# Find grass on Linux
#grassDir='/opt/nesi/CS400_centos7_bdw/GRASS/8.2.1-gimkl-2022a/grass82'

# Find grass on Windows
grassDir='C:/Program Files/GRASS GIS 8.2'

# Set the desired environment --------------------------------------------------------------------------------

# Import and reproject pop for pop at risk (PAR) calculation
pop <- 'G:/indonesia/idn_ppp_2020.tif' # 100 m

rgrass::initGRASS(gisBase = grassDir,
                  SG = rast(pop),
                  gisDbase = "grassdb",
                  location = "voronoi",  
                  mapset = "PERMANENT",
                  override = TRUE, 
                  remove_GISRC = TRUE)

rgrass::execGRASS("r.in.gdal",
                  input = pop,
                  output = "pop",
                  flags = c("overwrite"))

rgrass::execGRASS("g.list", type = "raster")
execGRASS("g.region", flags = "p", intern = TRUE)
execGRASS("r.info", map="pop")

# Step 1: Calculate 95th percentile
execGRASS("r.quantile", input="pop", percentiles=95, file="quantile_95.txt")

quantile_contents <- readLines("quantile_95.txt")

split_values <- strsplit(quantile_contents[1], ":")[[1]]

percentile_value <- as.numeric(split_values[3])  

# sharp round it
percentile_value <- round(percentile_value) 

# Rules
# Zero is not necessary 
#0 thru 5 = 0
#* = 1
#

#0 thru 5 = NULL
#* = 1
#

rules_file <- "my_reclass_rule.txt"
#writeLines(reclass_rules, con = rules_file)

#rules_file_path <- file.path(getwd(), "my_reclass_rule.txt")

# execGRASS("g.remove", type="raster", name="above_95th_percentile", flags="f")

# get it running
execGRASS("r.reclass", input="pop", output="above_95th_percentile", rules=rules_file, flags="overwrite")

rgrass::execGRASS("g.list", type = "raster") 

system("r.report map=above_95th_percentile units=c,p")

pixel_count <- execGRASS("r.stats", input = "above_95th_percentile", flags = c("n", "quiet"), intern = TRUE)
pixel_count


#  all 0 values to NULL
execGRASS("r.mapcalc", expression = "above_95th_masked = if(above_95th_percentile == 0, null(), above_95th_percentile)")


execGRASS("r.out.gdal", input = "above_95th_masked", output = "above_95th_masked.tif", format = "GTiff", flags = "f")

raster_above_95th <- rast("above_95th_masked.tif")

plot(raster_above_95th, main = "Above 95th Percentile Masked Raster", col = c("lightblue", "darkred"))

# Step 2: Use r.univar to count the number of 1s
r_stats <- execGRASS("r.univar", map = "above_95th_masked", flags = c("g", "t"), intern = TRUE)

rgrass::execGRASS("g.list", type = "raster")

r_stats <- read.table(text = r_stats, sep = "=")  # Convert the output into a table

r_stats


# -s   Generate random seed (result is non-deterministic)

execGRASS("r.random", input = "above_95th_masked", vector = 'high_pop_points', npoints = '100',  flags = "s")

rgrass::execGRASS("g.list", type = "vector")

# Export shapefile to inspect distribution
execGRASS("v.out.ogr", input="high_pop_points", output="high_pop_points.shp", format="ESRI_Shapefile")


# -----------
# Voronoi building

# Run Voronoi tessellation 
execGRASS("v.voronoi", input="high_pop_points", output="voronoi_polygons", flags = c("overwrite"))

# Optional Step 3: Convert Voronoi polygons back to a raster
#execGRASS("v.to.rast", input="voronoi_polygons", output="voronoi_raster", use="cat")

# Export Voronoi polygons to a shapefile
execGRASS("v.out.ogr", input="voronoi_polygons", output="voronoi_polygons.shp", format="ESRI_Shapefile", flags = c("overwrite"))

voronoi_polygons <- st_read("voronoi_polygons.shp")

#--------------------------------------------------------------------------------------------
# Add raster_above_95th to this plot

ggplot() +
  geom_sf(data = voronoi_polygons, fill = "lightblue", color = "black", lwd = 0.5) +
  theme_minimal() +
  labs(title = "Voronoi Polygons")

plot(raster_above_95th, main = "Above 95th Percentile Masked Raster", col = c("lightblue", "darkred"))


# Too SLOW

#  geom_raster(data = as.data.frame(raster_above_95th, xy = TRUE), 
 #             aes(x = x, y = y, fill = layer)) +


# Now force that to our districts

vector_file <- "C://Users//rdelaram//Documents//GitHub//eride/data//subset_districts.shp" 

keep <- c("Banten",
          "Jakarta",
          "West Java", 
          "Central Java",   
          "Yogyakarta"  ,
          "East Java"  , "Bali"    ) # 

regions <- read_sf(vector_file)

regions <- regions[regions$name_en %in% keep, ]

# Zooming in
bbox <- st_bbox(regions) 

intersection <- st_intersection(regions, voronoi_polygons)

exploded_regions <- st_union(regions)

plot(exploded_regions)

masked_voronoi <- st_intersection(voronoi_polygons, exploded_regions)

masked_voronoi <- st_sf(masked_voronoi)

# Get attributes from regions
regions_attr <- regions %>% 
  select(name)  

# Join the attributes based on spatial intersection

#if a cat falls within multiple regions, it will duplicate the entries in masked_voronoi 
# for each intersecting region.
#Therefore, it does not automatically determine which region has the majority of the area covered by a cat.

masked_voronoij <- masked_voronoi %>%
  st_join(regions_attr, join = st_intersects)

# Create the voronoi_id column


masked_voronoik <- masked_voronoij %>%
  mutate(voronoi_id = paste(name, cat, sep = "_"))  # Create voronoi_id

plot(masked_voronoik)

masked_voronoik$voronoi_id

# Export -----------------------------------------------

st_write(intersection, "high_pop_voronoi_java.shp", delete_dsn = TRUE)
st_write(masked_voronoi, "high_pop_voronoi_java_mask_id.shp", delete_dsn = TRUE)


# We want 1 cat - 1 region - A voronoi should be forced to one district only based on area
# Because of that, we get majority of area covered so every voronoi is only attributed to one region

# Join the attributes based on spatial intersection

intersected_data <- masked_voronoik %>%
  st_join(regions_attr, join = st_intersects)

intersected_data

intersected_data <- intersected_data %>%
  mutate(area = st_area(geometry))  # Add a column for area

intersected_data

# Group by cat and name, then summarize to find the region with the maximum area for each cat
majority_regions <- intersected_data %>%
  group_by(cat, name.x) %>%
  summarise(total_area = sum(area), .groups = 'drop') %>%
  group_by(cat) %>%
  slice(which.max(total_area)) %>%
  ungroup() %>%
  select(cat, name.x)  # Select only necessary columns

majority_regionsy <- intersected_data %>%
  group_by(cat, name.y) %>%
  summarise(total_area = sum(area), .groups = 'drop') %>%
  group_by(cat) %>%
  slice(which.max(total_area)) %>%
  ungroup() %>%
  select(cat, name.y)  # Select only necessary columns

majority_regionsy

nrow(majority_regions)
majority_regions

# Perform left join with masked_voronoi to get the majority region for each cat
masked_voronoi1 <- masked_voronoi %>%
  left_join(data.frame(majority_regions), by = "cat")

masked_voronoi1y <- masked_voronoi %>%
  left_join(data.frame(majority_regionsy), by = "cat")


colnames(masked_voronoi1)

# Create the voronoi_id column - forcing a voronoi to belong to only one region
masked_voronoi2 <- masked_voronoi1 %>%
  mutate(voronoi_id = paste(name.x, cat, sep = "_"))  # Use majority region's name


masked_voronoi2y <- masked_voronoi1y %>%
  mutate(voronoi_id = paste(name.y, cat, sep = "_"))  

nrow(masked_voronoi2)
nrow(masked_voronoi2y)
head(masked_voronoi2)
head(masked_voronoi2y)


# Plot of 1 cat one region
vorplot_forced <- ggplot() +
  geom_sf(data = regions, aes(fill = name), color = "black", alpha = 0.5) +  
  geom_sf(data = masked_voronoi2, fill = "white", color = "gray30", alpha = 0.4) + 
  geom_sf_text(data = regions, aes(label = name), size = 3, color = "black", check_overlap = TRUE) + 
  geom_sf_text(data = masked_voronoi2, aes(label = voronoi_id), size = 3, color = "black", check_overlap = TRUE) + 
  xlim(bbox[c("xmin", "xmax")]) + 
  ylim(bbox[c("ymin", "ymax")]) +
  theme_minimal() +
  labs(title = "High-Pop based Voronoi Polygons forced to districts by majority of area") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_viridis_d(name = "Districts")


vorplot_forcedy <- ggplot() +
  geom_sf(data = regions, aes(fill = name), color = "black", alpha = 0.5) +  
  geom_sf(data = masked_voronoi2y, fill = "white", color = "gray30", alpha = 0.4) + 
  geom_sf_text(data = regions, aes(label = name), size = 3, color = "black", check_overlap = TRUE) + 
  geom_sf_text(data = masked_voronoi2, aes(label = voronoi_id), size = 3, color = "black", check_overlap = TRUE) + 
  xlim(bbox[c("xmin", "xmax")]) + 
  ylim(bbox[c("ymin", "ymax")]) +
  theme_minimal() +
  labs(title = "High-Pop based Voronoi Polygons forced to districts by majority of area") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_viridis_d(name = "Districts")

#-------------------------------------------------------------------------------------------------------------
# Check this  - Why is Bali_96 not in Timur????
vorplot_forced # weird Bali
vorplot_forcedy #ALSO weird Bali
table(masked_voronoi2$cat)
table(masked_voronoi2$voronoi_id)
table(masked_voronoi2$name.x)
table(masked_voronoi2y$name.y)


# Plot without forcing regions - Sig S4
vorplot <- ggplot() +
  geom_sf(data = regions, aes(fill = name), color = "black", alpha = 0.5) +  
  geom_sf(data = masked_voronoi, fill = "white", color = "gray30", alpha = 0.4) + 
  geom_sf_text(data = regions, aes(label = name), size = 3, color = "black", check_overlap = TRUE) + 
  xlim(bbox[c("xmin", "xmax")]) + 
  ylim(bbox[c("ymin", "ymax")]) +
  theme_minimal() +
  labs(title = "Districts High-Pop based Voronoi Polygons") +
  theme(plot.title = element_text(hjust = 0.5)) + 
  scale_fill_viridis_d(name = "Districts")

vorplot

# Voronois per distict

rowSums(table(intersection$name, intersection$cat))

voronoi_polygons$cat

# Export shapefiles --------------------------
require(here)

setwd(here())
setwd('results')

st_write(masked_voronoi2, "districts_high_pop_voronoi_cat_forced.shp", delete_dsn = TRUE)

st_write(masked_voronoi2y, "districts_high_pop_voronoi_cat_forcedy.shp", delete_dsn = TRUE)

data.frame(masked_voronoi2$name.x, masked_voronoi2$voronoi_id)

# Export fig 

ggsave("districts_high_pop_voronoi_polygons_intersect.jpg", vorplot, width = 10, height = 8, dpi = 300)

ggsave("districts_high_pop_voronoi_cat_forced.jpg", vorplot, width = 10, height = 8, dpi = 300)

#-------------------------------------------------------------------------------------------------------------