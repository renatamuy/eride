# Script

source('00_packages.R')

setwd('data/')

gibb <- read_csv('HostSpecies_PREDICTS.csv')

gibbm <-gibb %>%  filter(Order == 'Chiroptera')

gibbm

iucn <- shapefile('D://OneDrive - Massey University//PD_2021//distribution_models//iucn_shapefile//MAMMALS_TERRESTRIAL_ONLY.shp')

head(iucn)

iucn[str_detect(iucn$binomial, pattern= 'lyra'),]

gibbm[str_detect(gibbm$`Host binomial`, pattern= 'lyra'), "Host binomial"] <- 'Lyroderma lyra'

i2 <- iucn[iucn$binomial %in% gibbm$`Host binomial`,]

setdiff( gibbm$`Host binomial`, unique(i2@data$binomial))

setdiff( unique(i2@data$binomial),  gibbm$`Host binomial`)

#"Megaderma lyra"    "Artibeus cinereus" "Artibeus phaeotis" "Artibeus toltecus"
 



nrow(i2)

# Who are the bat hosts that match my study region?

# Get hosts

# Get their IUCN range, see how much match

# Get your study extent

# Match bats that occur there

# Pull out the zoonotic pathogens they carry

# Export

#tell Dave and discuss about host quality


#-------------------------------------------------------------
