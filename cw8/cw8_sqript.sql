CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;

CREATE SCHEMA rasters;
CREATE SCHEMA vectors;

-- 6. Utwórz nową tabelę o nazwie uk_lake_district, gdzie zaimportujesz mapy
--	  rastrowe z punktu 1., które zostaną przycięte do granic parku narodowego
-- 	  Lake District.
CREATE TABLE rasters.uk_lake_district AS
SELECT ST_Clip(uk.rast, p.geom, true) 
FROM vectors.national_parks AS p, rasters.uk_250k AS uk
WHERE p.id = 1 AND ST_Intersects(uk.rast, p.geom);

ALTER TABLE rasters.uk_lake_district
ADD COLUMN rid SERIAL PRIMARY KEY;

CREATE INDEX idx_clip_rast_gist ON rasters.uk_lake_district
USING gist (ST_ConvexHull(st_clip));

SELECT AddRasterConstraints('rasters'::name,
'uk_lake_district'::name,'st_clip'::name);


-- 7. Wyeksportuj wyniki do pliku GeoTIFF.
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(st_clip), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM rasters.uk_lake_district;
----------------------------------------------
SELECT lo_export(loid, 'D:\studia\Semestr_5\BazyDanychPrzestrzennych\cw8\uk_lake_district.tiff')
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out;


-- 10. Policz indeks NDWI (to inny indeks niż NDVI) oraz przytnij wyniki do granic Lake District.
CREATE TABLE rasters.ndwi AS
WITH r1 AS (
	SELECT ST_Clip(s.rast, ST_Transform(p.geom, 4326), true) AS rast
	FROM vectors.national_parks AS p, rasters.s2_b03 AS s
	WHERE p.id = 1 AND ST_Intersects(s.rast, ST_Transform(p.geom, 4326))
),
r2 AS(
	SELECT ST_Clip(s.rast, ST_Transform(p.geom, 4326), true) AS rast
	FROM vectors.national_parks AS p, rasters.s2_b08 AS s
	WHERE p.id = 1 AND ST_Intersects(s.rast, ST_Transform(p.geom, 4326))
)
SELECT
	ST_MapAlgebra(r1.rast, r2.rast,
	'([rast1.val] - [rast2.val]) / ([rast1.val] +
	[rast2.val])::float','32BF'
	) AS rast
FROM r1, r2;

ALTER TABLE rasters.ndwi
ADD COLUMN rid SERIAL PRIMARY KEY;

CREATE INDEX idx_ndwi_rast_gist ON rasters.ndwi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('rasters'::name,
'ndwi'::name,'rast'::name);


-- 11. Wyeksportuj obliczony i przycięty wskaźnik NDWI do GeoTIFF.
CREATE TABLE tmp_out2 AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM rasters.ndwi;
----------------------------------------------
SELECT lo_export(loid, 'D:\studia\Semestr_5\BazyDanychPrzestrzennych\cw8\lake_district_ndwi.tiff')
FROM tmp_out2;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out2;


