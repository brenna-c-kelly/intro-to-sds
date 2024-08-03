
library(sf)
library(tmap)
library(dplyr)
library(stringr)
library(tidycensus)

acs_2020 <- load_variables(year = 2020,
                           dataset = "acs5")

acs_2020[which(acs_2020$name %in% c("B01001_026", paste0("B01001_03", rep(0:9)))), ]


ca <- get_acs(geography = "county",
              state = "CA",
              variables = c("B01001_026", # total female population
                            paste0("B01001_03", rep(0:9))),
              year = 2020,
              geometry = TRUE,
              output = "wide") |>
  select(!(ends_with("M"))) |> # remove margin of error columns
  mutate(female_of_ra = B01001_030E + B01001_031E + 
           B01001_032E + B01001_033E + B01001_034E +
           B01001_035E + B01001_036E + B01001_037E +
           B01001_038E + B01001_039E) |>
  rename(total_female = B01001_026E) |>
  mutate(female_of_ra_perc = female_of_ra / total_female) |>
  select(!(c(paste0("B01001_03", rep(0:9), "E")))) |>
  mutate(female_of_ra_perc = ifelse(is.na(female_of_ra_perc), 0, female_of_ra_perc))

ca <- ca[which(!st_is_empty(ca)), ]
ca_center <- st_centroid(st_union(ca))
st_geometry(ca_center)

aea <- "+proj=aea +lat_1=29.5 +lat_2=30.5 +lat_0=37.5 +lon_0=-96 +ellps=GRS80 +datum=NAD83"
ca <- st_transform(ca, st_crs(aea))

tm_shape(ca) +
  tm_polygons(col = "female_of_ra_perc", palette = "RdPu", style = "cont", lwd = 0)


# with centroids, bivariate
ca_centers <- read.csv("data/california/CenPop2020_Mean_CO06.csv")
ca_centers_sf <- st_as_sf(ca_centers, coords = c("LONGITUDE", "LATITUDE"), crs = 4326)
ca_centers_sf$geoid <- paste0(str_pad(ca_centers_sf$STATEFP, pad = "0", width = 2, side = "left"),
                              str_pad(ca_centers_sf$COUNTYFP, pad = "0", width = 3, side = "left"))
ca_centers_sf <- merge(ca_centers_sf, st_drop_geometry(ca), by.x = "geoid", by.y = "GEOID")

tm_shape(ca) +
  tm_polygons(col = "white", lwd = 0.2, title = "") +
  tm_shape(ca_centers_sf) +
  tm_dots(col = "female_of_ra_perc", size = "total_female", scale = 1.5, 
          palette = "RdPu", style = "cont", legend.is.portrait = FALSE,
          title = "% of Reproductive Age")

head(ca_centers_sf)
ca_centers_sf <- ca_centers_sf |>
  select(!(c("STATEFP", "COUNTYFP", "STNAME", 
             "POPULATION", "NAME")))

names(ca_centers_sf) <- c("geoid", "county_name", "f_denom", 
                          "f_ra", "f_ra_p", "geometry")

st_write(ca_centers_sf, "data/california/ca_county_centers.shp", append = FALSE)

test <- st_read("data/california/ca_county_centers.shp")

head(ca)
names(ca) <- c("geoid", "name", "f_denom", "f_ra", "f_ra_p", "geometry")
st_write(ca, "data/california/ca_counties.shp", append = FALSE)



## los angeles
ca <- get_acs(geography = "tract",
              state = "CA",
              variables = c("B01001_026", # total female population
                            paste0("B01001_03", rep(0:9))),
              year = 2020,
              geometry = TRUE,
              output = "wide")
la <- ca |>
  select(!(ends_with("M"))) |> # remove margin of error columns
  mutate(female_of_ra = B01001_030E + B01001_031E + 
           B01001_032E + B01001_033E + B01001_034E +
           B01001_035E + B01001_036E + B01001_037E +
           B01001_038E + B01001_039E) |>
  rename(total_female = B01001_026E) |>
  mutate(female_of_ra_perc = female_of_ra / total_female) |>
  select(!(c(paste0("B01001_03", rep(0:9), "E")))) |>
  mutate(female_of_ra_perc = ifelse(is.na(female_of_ra_perc), 0, female_of_ra_perc)) |>
  mutate(county_fips = str_sub(GEOID, start = 1, end = 5)) |>
  filter(county_fips == ("06037"))

la <- la[which(!st_is_empty(la)), ]

tm_shape(la) +
  tm_polygons(col = "female_of_ra_perc", palette = "RdPu", style = "cont", lwd = 0, 
              legend.is.portrait = TRUE, title = "Proportion \nof Reproductive Age")

la <- la |>
  select(!c("county_fips")) |>
  rename(geoid = GEOID,
         name = NAME,
         f_denom = total_female, 
         f_ra = female_of_ra, 
         f_ra_p = female_of_ra_perc)
st_write(la, "data/california/la_tracts.shp")

la_centers <- read.csv("data/california/CenPop2020_Mean_TR06.csv")
la_centers_sf <- st_as_sf(la_centers, coords = c("LONGITUDE", "LATITUDE"), crs = 4326)
la_centers_sf$geoid <- paste0(str_pad(la_centers_sf$STATEFP, pad = "0", width = 2, side = "left"),
                              str_pad(la_centers_sf$COUNTYFP, pad = "0", width = 3, side = "left"),
                              str_pad(la_centers_sf$TRACTCE, pad = "0", width = 6, side = "left"))
la_centers_sf <- la_centers_sf |>
  filter(COUNTYFP == 37)

la_centers_sf <- merge(la_centers_sf, st_drop_geometry(la), by.x = "geoid", by.y = "GEOID")
head(la_centers_sf)

tm_shape(la) +
  tm_polygons(col = "white", lwd = 0.25) +
  tm_shape(la_centers_sf) +
  tm_dots(col = "female_of_ra_perc", style = "cont", palette = "RdPu", 
          size = "female_of_ra", scale = 0.5, alpha = 0.7,
          legend.is.portrait = FALSE, title = "Proportion \nof Reproductive Age")

test <- la_centers_sf |>
  select(!c("STATEFP", "COUNTYFP", "TRACTCE", "POPULATION", "geoid_county")) |>
  rename(tract_name = NAME, 
         f_denom = total_female, 
         f_ra = female_of_ra, 
         f_ra_p = female_of_ra_perc)

st_write(test, "data/california/la_centers.shp")
test <- st_read("data/california/la_centers.shp")

tm_shape(la) +
  tm_polygons(col = "white", lwd = 0.25) +
  tm_shape(test) +
  tm_dots(col = "f_ra_p", style = "cont", palette = "RdPu", 
          size = "f_ra", scale = 0.5, alpha = 0.7,
          legend.is.portrait = FALSE, title = "Proportion \nof Reproductive Age")
