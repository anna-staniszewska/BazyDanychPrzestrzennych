CREATE EXTENSION postgis;

-- 4) Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty) położonych w odległości mniejszej 
--    niż 1000 jednostek od głównych rzek. Budynki spełniające to kryterium zapisz do osobnej tabeli tableB.
SELECT p.* INTO tableB FROM popp p, majrivers m 
WHERE p.f_codedesc = 'Building' 
AND ST_Distance(m.geom, p.geom) < 1000;

SELECT COUNT(*) FROM tableB;

-- 5) Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.
SELECT name, geom, elev INTO airportsNEW FROM airports;

-- 5a) Znajdź lotnisko, które położone jest najbardziej na:
 --zachód
SELECT name FROM airportsNEW
WHERE ST_X(geom) = (SELECT MIN(ST_X(geom)) FROM airportsNEW);

 --wschód
SELECT name FROM airportsNEW
WHERE ST_X(geom) = (SELECT MAX(ST_X(geom)) FROM airportsNEW);

-- 5b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie środkowym drogi 
--     pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB. Wysokość n.p.m. przyjmij dowolną.
INSERT INTO airportsNEW VALUES(
	'airportB',
	(SELECT ST_MakePoint(AVG(ST_X(geom)), AVG(ST_Y(geom))) FROM airportsNEW 
	WHERE name = 'ATKA' OR name = 'ANNETTE ISLAND'),
	30
);

-- 6) Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej 
--	  linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”.
SELECT ST_Area(ST_Buffer(ST_ShortestLine(l.geom, a.geom), 1000)) FROM lakes l, airportsNEW a
WHERE l.names = 'Iliamna Lake' AND a.name = 'AMBLER';

-- 7) Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących
--	  poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).
WITH TundraINFO
AS
(
	SELECT tr.vegdesc AS typ, ST_Area(ST_Collect(ST_Intersection(tu.geom, tr.geom))) AS pole
	FROM tundra tu, trees tr
	GROUP BY tr.vegdesc
),
SwampINFO
AS
(
	SELECT tr.vegdesc AS typ, ST_Area(ST_Collect(ST_Intersection(s.geom, tr.geom))) AS pole
	FROM swamp s, trees tr
	GROUP BY tr.vegdesc
)
SELECT t.typ, t.pole + s.pole AS pole 
FROM TundraINFO t INNER JOIN SwampINFO s
ON t.typ = s.typ;

