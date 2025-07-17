# Plot viruses ~ mammal hosts
# Virus layer source: Virion
# Source: Mammal hosts layer IUCN 2021
# Viruses from mammals filter

require(raster)
require(here)
require(vroom)
require(sf)
require(tidyverse)
require(fasterize)

setwd("D://OneDrive - Massey University//hostland//virion-main/Virion")

# open data
virion <- vroom("Virion.csv.gz")

# get a base raster
rbase <- raster('D://OneDrive - Massey University//_env//_env_27km_ss6//bio_1.tif')

# blank it for the world
r <- raster::raster(ext=extent(c(-180, 180, -90, 90)), crs = crs(rbase), res=res(rbase))

# get mammals
iucn <- st_read(dsn = 'D:/OneDrive - Massey University/_env/mammals/IUCN_2021',
                layer = 'MAMMALS_TERRESTRIAL_ONLY')

# get mammal viruses 
virion %>% filter(HostClass == "mammalia") %>%
  dplyr::select(Host, Virus) %>%
  distinct() %>%
  group_by(Host) %>%
  summarize(NVirus = n_distinct(Virus)) -> nvir

# get mammal viruses and join with mammals
iucn %>% mutate(binomial = tolower(binomial)) %>%
  left_join(nvir, by = c('binomial' = 'Host')) %>%
  filter(NVirus > 0) -> iucn

# number of mammal hosts
map.num.m <- fasterize(iucn, r, field = NULL, fun = 'count')

# number of mammal viruses
map.sum.m <- fasterize(iucn, r, field = "NVirus", fun = 'sum')

# model
modelhv <- glm(values(map.sum.m)~ values(map.num.m))

# export
setwd('C:/Users/rdelaram/Documents/GitHub/eride/results/')

jpeg("Figure_S3.jpg", width = 18, height = 18, units='cm', res = 300)
plot(values(map.sum.m)~ values(map.num.m), xlab='Mammal hosts', ylab='Viruses')
abline(modelhv, col='blue', lty=1, lwd=4)
dev.off()

# proportion of hosts with verbatim iucn range matches = 84%
n_distinct(iucn$binomial) / n_distinct(nvir$Host)

hosts <- raster::stack(map.num.m, map.sum.m )

#------------
setwd(here())

dir.create('results')
setwd('results')
dir.create('pull_virus_IUCN_2021')
setwd('pull_virus_IUCN_2021')

names(hosts) <- c("mammal_hosts", 'mammal_viruses')

# export rasters
#setwd('F://')
setwd(here())
setwd('results')
terra::writeRaster(hosts$mammal_hosts, file = paste(names(hosts)[1], "_27km.tif", sep=""), 
                    format="GTiff", 
                    bylayer=TRUE,
                    overwrite=TRUE)


raster::writeRaster(hosts$mammal_viruses, file = paste(names(hosts)[2], "_27km.tif", sep=""), 
                    format="GTiff", 
                    bylayer=TRUE,
                    overwrite=TRUE)

#-------------------------------------------------------------------------------------------