
library(sf)
library(tmap)
library(tidyverse)

house <- st_read("/Users/brenna/Downloads/snow/snow1/deaths_nd_by_house.shp")
pumps <- st_read("/Users/brenna/Downloads/snow/snow6/pumps.shp")
sewer <- st_read("/Users/brenna/Downloads/snow/snow7/sewergrates_ventilators.shp")

# light cleaning
# sort the pumps by their ID
pumps <- pumps |>
  arrange(ID)

pumps$name <- ifelse(pumps$name == "Tighborne St Pump\rTighborne St Pump\r",
                     "Tighborne St Pump", pumps$name)

# find the nearest pump to each household
house$nearest_pump <- st_nearest_feature(house, pumps)
summary(house$nearest_pump)
# note that we get the index of the nearest pump, but not the name

# to get the name, we'll merge with `pumps`
# we can't merge two features with geometry, so we'll drop the geometry from `pumps`
house <- merge(house, st_drop_geometry(pumps),
               by.x = "nearest_pump", by.y = "ID")

tm_shape(house) +
  tm_dots(col = "name", style = "cont", 
          palette = "Dark2", legend.show = FALSE) +
  tm_shape(pumps) +
  tm_dots(col = "name", size = 1, title = "Water pump",
          palette = "Dark2", shape = 17) +
  tm_layout(title = "Nearest water pump to\neach household", main.title.position = "center")

# now that each household is linked to a pump, calculate the number of deaths per household by the nearest pump
deaths_by_pump <- aggregate(house$deaths_nr, by = list(house$name), FUN = sum)
# did we find the guilty party?

# calculate the distance from each household to the Broad Street pump
#   since there were only 8 pumps, we easily identified the correct pump
house$distance_to_bsp <- st_distance(house, 
                                     pumps[which(pumps$name == "Broad St Pump"), ])

# let's map distance to the Broad Street Pump with dots proportional to the number of deaths
# and for good measure, let's also plot the Broad Street Pump itself
tm_shape(house) +
  tm_dots(col = "distance_to_bsp", style = "cont", size = "deaths", palette = "viridis") +
  tm_shape(pumps, filter = pumps$ID == 1) +
  tm_dots(col = "red", size = 1, shape = 17)


# before accepting John Snow's theory, cholera was thought to be caused by miasma, or particles in the air

# perform same procedures as above, but with sewer grates instead of pumps

##    we will make one modification
# note that there are far more sewer grates than water pumps. Let's calculate the *network* distance
sewer

sewer_vent <- sewer |>
  filter(ventilator == 1)

v_sewers <- st_is_within_distance(house, sewer_vent, dist = 100, sparse = TRUE)

v_sewers_count <- sapply(v_sewers, length) # this gives us the number of sewer ventilators within the specified distance
house <- cbind(house, 
               v_sewers_count) # add this information to the house dataframe

# and plot
tm_shape(house) +
  tm_dots(col = "v_sewers_count", style = "cont", palette = "inferno") +
  tm_shape(sewer_vent) +
  tm_dots(col = "red", shape = 15, size = 0.25)

# does there appear to be evidence that sewer grate ventilators are associated with cholera deaths?
cor.test(house$v_sewers_count, house$deaths)

# how does this compare to the association between the Broad Street pump and cholera deaths?
cor.test(house$distance_to_bsp, house$deaths)

pump_map <- tm_shape(house) +
  tm_dots(col = "black", style = "cont", alpha = 0.8, size = "deaths") +
  tm_shape(pumps, filter = pumps$ID == 1) +
  tm_dots(col = "red", size = 1, shape = 17)

sewer_map <- tm_shape(house) +
  tm_dots(col = "black", style = "cont", alpha = 0.8, size = "deaths") +
  tm_shape(sewer_vent) +
  tm_dots(col = "red", shape = 15, size = 0.25)

tmap_arrange(pump_map, sewer_map)




