CREATE EXTENSION postgis;

SELECT * FROM t2018_kar_buildings;

-- 1) Znajdź budynki, które zostały wybudowane lub wyremontowane 
--	  na przestrzeni roku (zmiana pomiędzy 2018 a 2019).
WITH NewINFO
AS
(
	SELECT * FROM t2019_kar_buildings
	WHERE NOT EXISTS (SELECT * FROM t2018_kar_buildings
				WHERE t2019_kar_buildings.polygon_id = t2018_kar_buildings.polygon_id)
),
RenovatedINFO
AS
(
	SELECT n.* FROM t2018_kar_buildings s, t2019_kar_buildings n
	WHERE s.polygon_id = n.polygon_id 
	AND ST_Equals(s.geom, n.geom) = FALSE
)
SELECT * INTO ChangeTable FROM NewINFO UNION SELECT * FROM RenovatedINFO;

SELECT * FROM ChangeTable;

-- 2) Znajdź ile nowych POI pojawiło się w promieniu 500 m
-- 	  od wyremontowanych lub wybudowanych budynków, które znalezione
--    zostały w zadaniu 1. Policz je wg ich kategorii.
WITH NewPOIINFO
AS
(
	SELECT * FROM t2019_kar_poi_table
	WHERE NOT EXISTS (SELECT * FROM t2018_kar_poi_table
				WHERE t2019_kar_poi_table.poi_id = t2018_kar_poi_table.poi_id)
)
SELECT p.type AS typ, COUNT(ST_Contains(ST_Buffer(c.geom, 500), p.geom)) AS ilosc
FROM ChangeTable c, NewPOIINFO p
GROUP BY p.type;

-- 3) Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli
--	  T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.
SELECT * INTO TransformedData FROM t2019_kar_streets;
ALTER TABLE TransformedData ALTER COLUMN geom 
TYPE geometry(MULTILINESTRING, 3068) USING ST_Transform(ST_SetSRID(geom,4326),3068) ;

SELECT ST_AsText(geom) FROM t2019_kar_streets;
SELECT ST_AsText(geom) FROM TransformedData;

-- 4) Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
CREATE TABLE input_points (geom GEOMETRY);
INSERT INTO input_points VALUES (ST_GeomFromText('POINT(8.36093 49.03174)', 4326));
INSERT INTO input_points VALUES (ST_GeomFromText('POINT(8.39876 49.00644)', 4326));

-- 5) Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie
--	  współrzędnych DHDN.Berlin/Cassini. Wyświetl współrzędne za pomocą funkcji ST_AsText().
ALTER TABLE input_points ALTER COLUMN geom 
TYPE geometry('POINT', 3068) USING ST_Transform(ST_SetSRID(geom,4326),3068);

SELECT ST_AsText(geom) FROM input_points;

-- 6) Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii
--	  zbudowanej z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. 
--	  Dokonaj reprojekcji geometrii, aby była zgodna z resztą tabel.							
SELECT * FROM t2019_kar_street_node  
WHERE ST_Contains(ST_Transform(ST_Buffer(ST_ShortestLine( 
	(SELECT geom FROM input_points LIMIT 1),			  
	(SELECT geom FROM input_points LIMIT 1 OFFSET 1))
							   		, 200), 4326), geom); 
	
-- 7) Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs)
--	  znajduje się w odległości 300 m od parków (LAND_USE_A).
WITH ParksBufferINFO
AS
(
	SELECT ST_Union(ST_Transform(ST_Buffer(ST_Transform(geom, 3068), 300), 4326)) 
	AS geom
	FROM t2019_kar_land_use_a
	WHERE type = 'Park (City/County)'
)
SELECT COUNT(p.*) FROM t2019_kar_poi_table p, ParksBufferINFO b 
WHERE p.type = 'Sporting Goods Store'
AND ST_Contains(b.geom, p.geom);

-- 8) Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES).
--	  Zapisz znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’.
SELECT DISTINCT(ST_Intersection(r.geom, w.geom)) INTO T2019_KAR_BRIDGES
FROM t2019_kar_railways r, t2019_kar_water_lines w;

SELECT * FROM T2019_KAR_BRIDGES;