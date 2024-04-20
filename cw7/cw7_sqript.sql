-- załadowanie rozszerzeń
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

-- sprawdzenie raster_columns
SELECT * FROM raster_columns;

--- Tworzenie rastrów z istniejących rastrów i interakcja z wektorami

-- Przykład 1. - ST_Intersects
CREATE TABLE staniszewska.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

-- 1. dodanie serial primary key:
alter table staniszewska.intersects
add column rid SERIAL PRIMARY KEY;

-- 2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_intersects_rast_gist ON staniszewska.intersects
USING gist (ST_ConvexHull(rast));

-- 3. dodanie raster constraints:
SELECT AddRasterConstraints('staniszewska'::name,
'intersects'::name,'rast'::name);


-- Przykład 2. - ST_Clip
CREATE TABLE staniszewska.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

alter table staniszewska.clip
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_clip_rast_gist ON staniszewska.clip
USING gist (ST_ConvexHull(st_clip));

SELECT AddRasterConstraints('staniszewska'::name,
'clip'::name,'st_clip'::name);


-- Przykład 3. - ST_Union
CREATE TABLE staniszewska.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

alter table staniszewska.union
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_union_rast_gist ON staniszewska.union
USING gist (ST_ConvexHull(st_union));

SELECT AddRasterConstraints('staniszewska'::name,
'union'::name,'st_union'::name);



--- Tworzenie rastrów z wektorów (rastrowanie)

-- Przykład 1. - ST_AsRaster
CREATE TABLE staniszewska.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

alter table staniszewska.porto_parishes
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_porto_rast_gist ON staniszewska.porto_parishes
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('staniszewska'::name,
'porto_parishes'::name,'rast'::name);


-- Przykład 2. - ST_Union
DROP TABLE staniszewska.porto_parishes; --> drop table porto_parishes first
CREATE TABLE staniszewska.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

alter table staniszewska.porto_parishes
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_porto_rast_gist ON staniszewska.porto_parishes
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('staniszewska'::name,
'porto_parishes'::name,'rast'::name);


-- Przyklad 3. - ST_Tile
DROP TABLE staniszewska.porto_parishes; --> drop table porto_parishes first
CREATE TABLE staniszewska.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1 
)
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

alter table staniszewska.porto_parishes
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_porto_rast_gist ON staniszewska.porto_parishes
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('staniszewska'::name,
'porto_parishes'::name,'rast'::name);



--- Konwertowanie rastrów na wektory (wektoryzowanie)

-- Przykład 1. - ST_Intersection
create table staniszewska.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

-- Przykład 2. - ST_DumpAsPolygons
CREATE TABLE staniszewska.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,
(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);



--- Analiza rastrów

-- Przykład 1. - ST_Band
CREATE TABLE staniszewska.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

CREATE INDEX idx_landsat_nir_rast_gist ON staniszewska.landsat_nir
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('staniszewska'::name,
'landsat_nir'::name,'rast'::name);


-- Przykład 2. - ST_Clip
CREATE TABLE staniszewska.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

CREATE INDEX idx_paranhos_dem_rast_gist ON staniszewska.paranhos_dem
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('staniszewska'::name,
'paranhos_dem'::name,'rast'::name);


-- Przykład 3. - ST_Slope
CREATE TABLE staniszewska.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM staniszewska.paranhos_dem AS a;

CREATE INDEX idx_paranhos_slope_rast_gist ON staniszewska.paranhos_slope
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('staniszewska'::name,
'paranhos_slope'::name,'rast'::name);


-- Przykład 4. - ST_Reclass
CREATE TABLE staniszewska.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM staniszewska.paranhos_slope AS a;

CREATE INDEX idx_paranhos_slope_reclass_rast_gist ON staniszewska.paranhos_slope_reclass
USING gist (ST_ConvexHull(st_reclass));

SELECT AddRasterConstraints('staniszewska'::name,
'paranhos_slope_reclass'::name,'st_reclass'::name);


-- Przykład 5. - ST_SummaryStats
SELECT st_summarystats(a.rast) AS stats
FROM staniszewska.paranhos_dem AS a;


-- Przykład 6. - ST_SummaryStats oraz Union
SELECT st_summarystats(ST_Union(a.rast))
FROM staniszewska.paranhos_dem AS a;


-- Przykład 7. - ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
	SELECT st_summarystats(ST_Union(a.rast)) AS stats
	FROM staniszewska.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;


-- Przykład 8. - ST_SummaryStats w połączeniu z GROUP BY
WITH t AS (
	SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
	b.geom,true))) AS stats
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
	group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;


-- Przykład 9. - ST_Value
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;


-- Przykład 10. - ST_TPI
create table staniszewska.tpi30 as -- czas: 27s 638ms
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

CREATE INDEX idx_tpi30_rast_gist ON staniszewska.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('staniszewska'::name,
'tpi30'::name,'rast'::name);


-- Problem do samodzielnego rozwiązania
create table staniszewska.tpi30_2 as -- czas: 1s 304ms
select ST_TPI(a.rast,1) as rast
from rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

CREATE INDEX idx_tpi30_2_rast_gist ON staniszewska.tpi30_2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('staniszewska'::name,
'tpi30_2'::name,'rast'::name);



--- Algebra map

-- Przykład 1. - Wyrażenie Algebry Map
CREATE TABLE staniszewska.porto_ndvi AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(r.rast, 1, r.rast, 4,
	'([rast2.val] - [rast1.val]) / ([rast2.val] +
	[rast1.val])::float','32BF'
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON staniszewska.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('staniszewska'::name,
'porto_ndvi'::name,'rast'::name);


-- Przykład 2. – Funkcja zwrotna
create or replace function staniszewska.ndvi(
	value double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
	--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
	RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
	[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

CREATE TABLE staniszewska.porto_ndvi2 AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
	r.rid,ST_MapAlgebra(r.rast, ARRAY[1,4],
	'staniszewska.ndvi(double precision[],
	integer[],text[])'::regprocedure, --> This is the function!
	'32BF'::text
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON staniszewska.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('staniszewska'::name,
'porto_ndvi2'::name,'rast'::name);



--- Eksport danych

-- Przykład 1. - ST_AsTiff
SELECT ST_AsTiff(ST_Union(rast))
FROM staniszewska.porto_ndvi;


-- Przykład 2. - ST_AsGDALRaster
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM staniszewska.porto_ndvi;


-- lista formatów obsługiwanych przez bibliotekę GDAL
SELECT ST_GDALDrivers();


-- Przykład 3 - Zapisywanie danych na dysku za pomocą dużego obiektu
-- 				(large object,lo)
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
	ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
	'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM staniszewska.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'D:\studia\Semestr_5\BazyDanychPrzestrzennych\cw7\myraster.tiff') --> Save the file in a place where
-- the user postgres have access. In windows a flash drive usualy works fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.