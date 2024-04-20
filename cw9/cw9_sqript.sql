CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

CREATE TABLE raster_union AS SELECT ST_Union(rast) FROM "Exports";
