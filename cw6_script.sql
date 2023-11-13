CREATE EXTENSION postgis;

--- 0. Utwórz tabelę obiekty. W tabeli umieść nazwy i geometrie obiektów przedstawionych
---	   poniżej. Układ odniesienia ustal jako niezdefiniowany. Definicja geometrii
---	   powinna odbyć się za pomocą typów złożonych, właściwych dla EWKT.
CREATE TABLE obiekty (nazwa char(7), geom geometry);

INSERT INTO obiekty VALUES ('obiekt1', 'COMPOUNDCURVE( (0 1,1 1), CIRCULARSTRING(1 1,2 0,3 1,4 2,5 1), (5 1,6 1) )');
INSERT INTO obiekty VALUES ('obiekt2', 'CURVEPOLYGON( COMPOUNDCURVE((10 2,10 6,14 6), CIRCULARSTRING(14 6,16 4,14 2), 
							CIRCULARSTRING(14 2,12 0,10 2)), CIRCULARSTRING(11 2,12 3,13 2,12 1,11 2))');
INSERT INTO obiekty VALUES ('obiekt3', 'TRIANGLE((7 15,10 17,12 13,7 15))');
INSERT INTO obiekty VALUES ('obiekt4', 'MULTILINESTRING((20 20,25 25,27 24,25 22,26 21,22 19,20.5 19.5))');
INSERT INTO obiekty VALUES ('obiekt5', 'MULTIPOINT((30 30 59), (38 32 234))');
INSERT INTO obiekty VALUES ('obiekt6', 'GEOMETRYCOLLECTION(POINT(4 2), LINESTRING(1 1,3 2))');


--- 1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół
---	   najkrótszej linii łączącej obiekt 3 i 4.
SELECT ST_Area(ST_Buffer(ST_ShortestLine(geom, (SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')), 5)) 
FROM obiekty WHERE nazwa = 'obiekt3';


--- 2. Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie?
---	   Zapewnij te warunki.
UPDATE obiekty SET geom = 
(SELECT ST_AsText(ST_MakePolygon(ST_LineMerge(
	ST_Collect(geom, 'MULTILINESTRING((20.5 19.5,20 20))'))))
FROM obiekty
WHERE nazwa = 'obiekt4')
WHERE nazwa = 'obiekt4';

SELECT ST_AsText(geom) FROM obiekty WHERE nazwa = 'obiekt4';

TRUNCATE obiekty;
--- 3. W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.
INSERT INTO obiekty VALUES ('obiekt7', (SELECT ST_Collect(geom, 
			(SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')) 
						FROM obiekty WHERE nazwa = 'obiekt3'));

SELECT ST_AsText(geom) FROM obiekty WHERE nazwa = 'obiekt7';


--- 4. Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały
---	   utworzone wokół obiektów nie zawierających łuków.
SELECT SUM(ST_Area(ST_Buffer(geom, 5))) FROM obiekty WHERE ST_HasArc(geom) = FALSE;
