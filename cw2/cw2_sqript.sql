--- 2
CREATE DATABASE zad2_base;

--- 3
CREATE EXTENSION postgis;

--- 4/5
CREATE TABLE budynki (id INT, geometria GEOMETRY, nazwa CHAR(9));
INSERT INTO budynki VALUES (1, ST_GeomFromText('POLYGON((8 4,10.5 4,10.5 1.5,8 1.5,8 4))', -1), 'BuildingA');
INSERT INTO budynki VALUES (2, ST_GeomFromText('POLYGON((4 7,6 7,6 5,4 5,4 7))', -1), 'BuildingB');
INSERT INTO budynki VALUES (3, ST_GeomFromText('POLYGON((3 8,5 8,5 6,3 6,3 8))', -1), 'BuildingC');
INSERT INTO budynki VALUES (4, ST_GeomFromText('POLYGON((9 9,10 9,10 8,9 8,9 9))', -1), 'BuildingD');

CREATE TABLE drogi (id INT, geometria GEOMETRY, nazwa CHAR(5));
INSERT INTO drogi VALUES (1, ST_GeomFromText('LINESTRING(0 4.5,12 4.5)', -1), 'RoadX');
INSERT INTO drogi VALUES (2, ST_GeomFromText('LINESTRING(7.5 0,7.5 10.5)', -1), 'RoadY');

CREATE TABLE punkty_informacyjne (id INT, geometria GEOMETRY, nazwa CHAR(1));
INSERT INTO punkty_informacyjne VALUES (1, ST_GeomFromText('POINT(1 3.5)', -1), 'G');
INSERT INTO punkty_informacyjne VALUES (2, ST_GeomFromText('POINT(5.5 1.5)', -1), 'H');
INSERT INTO punkty_informacyjne VALUES (3, ST_GeomFromText('POINT(9.5 6)', -1), 'I');
INSERT INTO punkty_informacyjne VALUES (4, ST_GeomFromText('POINT(6.5 6)', -1), 'J');
INSERT INTO punkty_informacyjne VALUES (5, ST_GeomFromText('POINT(6 9.5)', -1), 'K');

--- 6a
SELECT SUM(ST_Length(geometria)) FROM drogi;

--- 6b
SELECT ST_AsText(geometria), ST_Area(geometria), ST_Perimeter(geometria) FROM budynki
WHERE nazwa = 'BuildingA';

--- 6c
SELECT nazwa, ST_Area(geometria) FROM budynki
ORDER BY nazwa;

--- 6d
SELECT nazwa, ST_Perimeter(geometria) FROM budynki
ORDER BY ST_Area(geometria) DESC
LIMIT 2;

--- 6e
SELECT ST_Distance((SELECT geometria FROM budynki WHERE nazwa = 'BuildingC'), 
				   (SELECT geometria FROM punkty_informacyjne WHERE nazwa = 'G'));
				   
--- 6f
SELECT ST_Area(ST_Difference((SELECT geometria FROM budynki WHERE nazwa = 'BuildingC'),
					 (SELECT ST_Buffer(geometria, 0.5) FROM budynki WHERE nazwa = 'BuildingB')));

--- 6g.1
SELECT nazwa, FROM budynki 
WHERE ST_Y(ST_Centroid(geometria)) > 
ST_Y((SELECT (ST_Centroid(geometria)) FROM drogi WHERE nazwa = 'RoadX')); 

--- 6g.2
SELECT ST_Area(ST_SymDifference(geometria, ST_GeomFromText('POLYGON((4 7,6 7,6 8,4 8,4 7))', -1))) 
FROM budynki
WHERE nazwa = 'BuildingC';