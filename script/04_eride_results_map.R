#-----------------------------------------------------------------------------------
# Panels containing eRIDE results using z value for SAR at 0.2 and 0.3
#
#
#-----------------------------------------------------------------------------------

gc()

require(here)
require(rnaturalearth)
require(rnaturalearthdata)
require(tidyverse)
require(tidyterra)
require(ggpubr)

here()

setwd('E:/eride_scales_z0p20')

bio <- terra::rast('biodiversity_500.tif')

# eRIDE

eride <- terra::rast('eRIDE_500.tif')

# Population at risk 

par <- terra::rast('PAR_500.tif')


#

world_map <- map_data("world")

# Filter for Indonesia and Java
indonesia_map <- world_map %>%
  filter(region == "Indonesia")

#---------------------------------------------
# https://dieghernan.github.io/tidyterra/articles/palettes.html
# Panel A Estimated relative diversity from SAR 

biop <- ggplot() +
  geom_spatraster(data = bio) +
  scale_fill_whitebox_c(palette = "soft" )+
    labs(title = "",  fill = "Estimated relative \n diversity from SAR",
      subtitle = ""  ) + theme_minimal() + theme(legend.position = "bottom")

biop


eridep <- ggplot() +
  geom_spatraster(data = eride) +
  scale_fill_grass_c(palette = "kelvin", use_grass_range = FALSE)+
  labs(title = "",
       fill = "Estimated risk for \n  novel infectious disease \n emergence (eRIDE)",
       subtitle = ""  ) + theme_minimal() + theme(legend.position = "bottom")

eridep

parp <- ggplot() +
  geom_spatraster(data = par )  +
  scale_fill_grass_c(  palette = "inferno", use_grass_range = FALSE,
    breaks = c(0, 250, 500) )+
  labs(title = "",
       fill = "Population \n at risk (PAR)",
       subtitle = ""  ) + theme_minimal() + theme(legend.position = "bottom")

parp

#scale_fill_gradientn(values=scales::rescale(c(min(map_dat$ExpY), median(map_dat$ExpY), mean(map_dat$ExpY),max(map_dat$ExpY))), colours=brewer.pal(9,"OrRd")) +

#----------------- z = 0.28

setwd('E:/eride_scales_z0p28')

bioz <- terra::rast('biodiversity_500.tif')

# eRIDE

eridez <- terra::rast('eRIDE_500.tif')

# Population at risk 

parz <- terra::rast('PAR_500.tif')

#---------------------------------------------

# Panel A Estimated relative diversity from SAR 

biopz <- ggplot() +
  geom_spatraster(data = bioz) +
  scale_fill_whitebox_c(palette = "soft" )+
  labs(title = "",  fill = "Estimated relative \n diversity from SAR",
       subtitle = ""  ) + theme_minimal() + theme(legend.position = "bottom")

biopz


eridepz <- ggplot() +
  geom_spatraster(data = eridez) +
  scale_fill_grass_c(palette = "kelvin", use_grass_range = FALSE)+
  labs(title = "",
       fill = "Estimated risk for \n  novel infectious disease \n emergence (eRIDE)",
       subtitle = ""  ) + theme_minimal() + theme(legend.position = "bottom")

eridepz

parpz <- ggplot() +
  geom_spatraster(data = parz )  +
  scale_fill_grass_c(  palette = "inferno", use_grass_range = FALSE,
                       breaks = c(0, 500, 1000) )+
  labs(title = "",
       fill = "Population \n at risk (PAR)",
       subtitle = ""  ) + theme_minimal() + theme(legend.position = "bottom")

parpz

#-------------------
setwd(here())
setwd('results')


ggarrange(biop, biopz, eridep, eridepz, parp,parpz,  ncol = 2, nrow = 3,
          labels = c("A", "B", "C", 'D', 'E', 'F'))


# export 
ggsave(filename= 'eride_map_500m.jpg', dpi=400, width=28, height = 25, units = 'cm')


#--------------------------------

