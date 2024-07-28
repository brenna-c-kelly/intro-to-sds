# Introduction to Spatial Data Science
A workshop prepared for the Department of Population Health Sciences at the University of Utah, scheduled for 8/16/24.

In this repository, you'll find three modules:  
1. Spatial data  
2. Spatial functions  
3. Mapmaking  

These modules are designed to be taught along with a lecture. We will work through the code together and discuss. At the end of each module, there are resources and bonus exercises (for the curious).

**Module 1. Spatial data**  
This module gives a brief introduction to spatial data and getting started with the `sf` package in R. We work with spatial point and polygon datasets, create sf objects, and review essential features of spatial data (e.g., coordinate reference systems).  

An option exercise is provided at the end of this module in which we practice with UK district polygons and point locations of pubs. We create an sf object from the pub coordinates, transform the CRS, and practice spatial filtering. Students choose one district, create a 5-km buffer, and examine the number of pubs within the district and nearby the district.  

**Module 2. Spatial functions**  
In this module, we examine a classic case study in spatial epidemiology: the 1854 Broad Street cholera outbreak. Using John Snow's survey data, we calculate the nearest water pump to each household to identify the culprit. We then calculate distance to the Broad Street Pump and determine it's correlation with household deaths. Maps are produced at each step.

In the second half of this module, we investigate the miasma hypothesis for the cholera outbreak. We determine how many sewer ventilation grates are within a certain distance of each household. We calculate the correlation with household deaths and compare with the Broad Street pump results.

**Module 3. Mapmaking**  
