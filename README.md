[![wercker status](https://app.wercker.com/status/93eeedc287da0173cfaeefb52835f631/s/master "wercker status")](https://app.wercker.com/project/byKey/93eeedc287da0173cfaeefb52835f631)

Source: http://www2.stat.duke.edu/~cr173/Sta523_Fa16/hw/hw5.html


## Background
New York City is at the forefront of the open data movement among local, state and federal governments. They have made publicly available a huge amount of data (NYC Open Data) on everything from street trees, to restaurant inspections, to parking violations. It is the last of these that we will be focusing on for this homework assignment.


## Tasks

For this first task our job is to attempt to geocode (find latitude and longitude for each entry) as much of the data as possible using the given variables. The data contains all parking violations from in the five boroughs of New York City from between August 2013 and June 2014. We will simplify matters somewhat by focusing our analyses solely on Manhattan (excluding Brooklyn, the Bronx, Queens, and Staten Island). 

The ultimate goal of this project is to reconstruct the boundaries of the 22 Manhattan New York City police precincts (numbered between 1 and 34). The parking violation data set contains the column, Violation.Precinct, that lists the police precinct in which the violation ostensibly took place. Our goal is to take this data along with the geocoded locations from Task 1 and generate a set of spatial polygons that represents the boundaries of the precincts. We produces a GeoJSON file called precinct.json as output.
