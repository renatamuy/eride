#-----------------------------------------------------------------------------------
# Panels containing eRIDE results using z value for SAR at 0.2 and 0.3
#
# R. Muylaert 2025
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


# pop 
#popr <- terra::rast('G:/indonesia/idn_ppp_2020.tif')

# bio

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


summary(raster::values(par))

# max 949.4

parp <-  ggplot() +
  geom_spatraster(data = par) +
  scale_fill_gradientn(
    colours = hcl.colors(10, palette = "inferno"),
    trans = "log10",
    breaks = scales::trans_breaks("log10", function(x) 10^x),
    labels = scales::trans_format("log10", scales::math_format(10^.x)),
    na.value = "transparent" 
  ) +
  labs(
    title = "",
    fill = "Population \n at risk (PAR)",
    subtitle = "") + 
  theme_minimal() + theme(legend.position = "bottom")


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
  geom_spatraster(data = parz) +
  scale_fill_gradientn(
    colours = hcl.colors(10, palette = "inferno"),
    trans = "log10",
    breaks = scales::trans_breaks("log10", function(x) 10^x),
    labels = scales::trans_format("log10", scales::math_format(10^.x)),
    na.value = "transparent"  # Makes NA values transparent instead of gray
  ) +
  labs(
    title = "",
    fill = "Population \n at risk (PAR)",
    subtitle = "") + 
  theme_minimal() + theme(legend.position = "bottom")

parpz


#-------------------
setwd(here())
setwd('results')

ggarrange(biop, biopz, eridep, eridepz, parp,parpz,  ncol = 2, nrow = 3,
          labels = c("A", "B", "C", 'D', 'E', 'F'))


# export 
setwd('Figures/')
ggsave(filename= 'Fig_01.jpg', dpi=400, width=28, height = 25, units = 'cm')
ggsave(filename= 'Fig_01.tif', dpi=400, width=28, height = 25, units = 'cm')

# Comparing the effect of changing z in the SAR iodiversity  calculation and other components
# Summary table with value comparison

get_object_name <- function(x, var_list) {
  name <- names(var_list)[which(sapply(var_list, function(y) identical(y, x)))]
  return(name)
}

recebe <- data.frame()

varis <- list(bio = bio, bioz = bioz, eride = eride, edirez = eridez, par = par, parz = parz)

for(v in 1:length(varis) ) {
  
 temp <- data.frame(t(summary(varis[[v]])))

 temp$tag <- get_object_name(varis[[v]], varis)
 
 recebe <-rbind(recebe, temp)
 
  }

str(recebe)

recebe$Var2 <- NULL

recebe$Freq

data <- recebe %>%
  separate(Freq, into = c("statistic", "value"), sep = ":") %>%
  mutate(value = as.numeric(trimws(value)))  # Clean and convert the 'value' column to numeric


unique(data$statistic)

data

data <- data %>%
  mutate(z = ifelse(grepl("z$", tag), "z  = 0.30", "z  = 0.20"))

str(data$Var1)
data$Var1 <- gsub(" ", "", data$Var1)

data$Components <- as.factor(data$Var1)

levels(data$Components)



comparison_plot <- data %>% 
  filter(statistic %in% c("Mean   ")) %>% 
  ggplot(aes(x = z, y = value, fill = statistic)) +
  facet_wrap(~Components) +
  geom_bar(stat = "identity", position = "dodge", show.legend = TRUE) +
  labs(
    title = "",
    x = "Mean",
    y = "Value"
  ) + 
  theme_minimal() + 
  scale_fill_grey()+
  labs(fill = '')+   theme( axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "none")

setwd(here())
setwd('results')

comparison_plot


data500m <- data %>% filter(statistic %in% c("Mean   "))

data500m

# At z=0.3, biodiversity was approximately twice as large than at z=0.2
# 77% higher values for eRIDE and 62% higher values for PAR (Table SX)

10.77 /5.26

4.30 /2.42

26.25 /16.11

require(xlsx)

#write.xlsx(data500m, file = 'Table_z_data500m.xlsx', row.names = FALSE)


ggsave(comparison_plot, filename= 'Fig_S1.jpg', dpi=400, width=10, height = 9, units = 'cm')
ggsave(comparison_plot, filename= 'Fig_S1.tif', dpi=400, width=10, height = 9, units = 'cm')
# Do it for all scales???
# If yes, we can run a wilcoxon's test


#--------------------------------




#-------------------------------------------------------------------------------------------------------------