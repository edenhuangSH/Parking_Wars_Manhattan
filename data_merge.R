library(dplyr)
library(sf)

# load data
load('/data/nyc_parking/NYParkingViolations.Rdata')
pluto = st_read('/data/nyc_parking/pluto_manhattan/MNMapPLUTO.shp')

# filter pluto to address, longitude and latitude
pluto_xy = data.frame(
    pluto$Address,
    st_centroid(pluto) %>%
        unlist() %>%
        matrix(ncol=2,byrow=TRUE),
    stringsAsFactors = FALSE
) %>%
    setNames(c('address', 'x', 'y'))

# filter nyc to address and precint
man_precincts = c(1, 5, 6, 7, 9, 10, 13, 14, 17, 18, 19, 20, 22, 23,
                    24, 25, 26, 28, 30, 32, 33, 34)
nyc_man = nyc %>%
    mutate(address = paste(House.Number, Street.Name)) %>%
    filter(Violation.Precinct %in% man_precincts) %>%
    select(address, precinct = Violation.Precinct)

rm(nyc, pluto)

# Clean data -------------------------------------------------------------

# make sure data is in the right case
nyc_man$address  = sapply(nyc_man$address, toupper)
pluto_xy$address = sapply(pluto_xy$address, toupper)

# remove NA values due to no house address
nyc_man$address = gsub('\\bNA \\b', '', nyc_man$address)

# replace street abbreviations with long form
# E with EAST, PL with PLACE, ST with STREET, etc...
abbrev = rbind( c('(?<!\\/)\\bE\\b(?!\\/)', 'EAST'),
                c('(?<!\\/)\\bW\\b(?!\\/)', 'WEST'),
                c('(?<!\\/)\\bS\\b(?!\\/)', 'SOUTH'),
                c('(?<!\\/)\\bN\\b(?!\\/)', 'NORTH'),
                c('\\bPL\\b', 'PLACE'),
                c('\\bAVE\\b', 'AVENUE'),
                c('\\bBLVD\\b', 'BOULEVARD'),
                c('\\bCT\\b', 'COURT'),
                c('\\bCIR\\b', 'CIRCLE'),
                c('\\bDR[V]*\\b', 'DRIVE'),
                c('\\bLN\\b', 'LANE'),
                c('\\bRD\\b', 'ROAD'),
                c('\\bST$', 'STREET'),
                c('\\bSTR[T]*\\b', 'STREET')
                )

for (i in seq_len(nrow(abbrev))) {
    pluto_xy$address = gsub(abbrev[i,1], abbrev[i,2],
                            pluto_xy$address, perl = TRUE)
    nyc_man$address  = gsub(abbrev[i,1],abbrev[i,2],
                            nyc_man$address, perl = TRUE)
}

# remove ordinal names, 1ST to 1, 2ND to 2, 3RD to 3, etc...
ord = rbind(c('(?<=[0-9])ST\\b', ''),
            c('(?<=[0-9])ND\\b', ''),
            c('(?<=[0-9])RD\\b', ''),
            c('(?<=[0-9])TH\\b', '')
            )

for (i in seq_len(nrow(ord))) {
    pluto_xy$address = gsub(ord[i,1], ord[i,2],
                            pluto_xy$address, perl = TRUE)
    nyc_man$address  = gsub(ord[i,1], ord[i,2],
                            nyc_man$address, perl = TRUE)
}

# merging data ----------------------------------------------------------

nyc_geo = inner_join(nyc_man, pluto_xy)
save(nyc_geo, file = "nyc_geo.Rdata")
