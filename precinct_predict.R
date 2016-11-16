library(raster)
library(dplyr)
library(ggplot2)
library(sf)
library(sp)
library(xgboost)

# load nyc data and rasterize a grid of prediction locations -----------
nyc_geo = readRDS(file='nyc_geo.RDS')
nybb = st_read("/data/nyc_parking/nybb/", quiet=TRUE)
manh = nybb %>% filter(BoroName == "Manhattan")

ext = st_bbox(manh) %>% .[c("xmin","xmax","ymin","ymax")] %>% extent()
r = raster(ext, ncol=100, nrow=300)
r = rasterize(as(manh,"Spatial"),r)

pred_cells = which(!is.na(r[]))
pred_locs = xyFromCell(r, pred_cells)

# sample from nyc geo data ----------------------------------------------

man_precincts = c(1, 5, 6, 7, 9, 10, 13, 14, 17, 18, 19, 20, 22, 23,
                  24, 25, 26, 28, 30, 32, 33, 34)
nyc_geo_reduced = data.frame()
nsamp = 1000
for (i in man_precincts) {

    x = nyc_geo[nyc_geo$precinct == i,]$x
    y = nyc_geo[nyc_geo$precinct == i,]$y

    # reject samples that are outside 90% quantile
    indx = which(x > quantile(x, 0.05) & x < quantile(x, 0.95))
    indy = which(y > quantile(y, 0.05) & y < quantile(y, 0.95))
    ind = intersect(indx, indy)
    x = x[ind]
    y = y[ind]
    n = length(ind)

    if (n > nsamp) {
        # sample nsamp number of observations from each precinct
        k = sample(seq_len(n), nsamp)
        x = x[k]
        y = y[k]
        n = nsamp
    }
    nyc_geo_reduced = rbind(nyc_geo_reduced, cbind(x, y, rep(i, n)))
}
nyc_geo_reduced = setNames(nyc_geo_reduced, c('x', 'y', 'precinct'))

# fit gradient boosted model ---------------------------------------------

library(xgboost)

precincts = factor(nyc_geo_reduced$precinct) %>% levels()
y = (factor(nyc_geo_reduced$precinct) %>% as.integer()) - 1L
x = nyc_geo_reduced %>% select(x,y) %>% as.matrix()

dtrain = xgb.DMatrix(x, label = y)
dtest  = xgb.DMatrix(pred_locs)

set.seed(0)
xgb_params = list(
    seed = 0,
    colsample_bytree = 0.8,
    subsample = 0.8,
    eta = 0.1,
    objective = 'multi:softmax',
    max_depth = 6,
    min_child_weight = 100
)

res = xgb.cv(data = dtrain,
             nround = 1000,
             early_stopping_rounds = 20,
             nfold = 5,
             verbose = 0,
             num_class = length(precincts))

m = xgboost(data=x,
            label=y,
            nthead=4,
            nround=res$best_iteration,
            verbose = 0,
            num_class=length(precincts))

pred_xgb = predict(m, newdata=as.matrix(pred_locs))
pred_xgb = precincts[pred_xgb+1]
r.xgb = r
r.xgb[pred_cells] = as.numeric(pred_xgb)

# use polygonizer to find police districts -------------------------------

source("polygonizer.R")
p = polygonizer(r.xgb)
p = st_transform(p, 4326)
st_write(p,"precincts.json", "data", driver="GeoJSON", quiet=TRUE)
