DROP MATERIALIZED VIEW IF EXISTS country_measurements;

DROP TABLE IF EXISTS measurements;

-- NOTE: Clip to avoid "ERROR:  transform: tolerance condition error (-20)"
UPDATE
    countries
SET
    wkb_geometry = ST_Intersection(
        wkb_geometry,
        'SRID=4326;POLYGON((-179 -89, -179 89, 179 89, 179 -89, -179 -89))' :: geometry
    );

-- Set seed so random data is same every time we run this
SET
    seed TO 1;

-- Create readings table
CREATE TABLE measurements (
    id SERIAL PRIMARY KEY,
    val INTEGER,
    geom GEOMETRY(POINT, 4326)
);

CREATE INDEX ON measurements USING GIST (geom);

-- Populate readings table with randomly generated measurments across all countries
WITH merged_countries AS (
    -- Merge all countries into single geometry
    SELECT
        ST_Union(wkb_geometry) as geom
    FROM
        countries
    WHERE
        iso_a3 != 'ATA' -- ignore antarctica
)
INSERT INTO
    measurements(geom, val)
SELECT
    (
        ST_Dump(
            ST_GeneratePoints(
                merged_countries.geom,
                -- Num of points to generate, 1M takes around 18s
                1000000,
                1
            )
        )
    ).geom,
    random() * 1000 AS val
from
    merged_countries;

VACUUM ANALYZE measurements;

-- Create a materialized view joining the measurements to the countries in which they belong, 
-- NOTE: 1M takes around 13m
CREATE MATERIALIZED VIEW country_measurements AS (
    SELECT
        measurements.val,
        ST_Transform(
            ST_SnapToGrid(measurements.geom, 1),
            3857
        ) as geom,
        countries.iso_a3 as country
    FROM
        measurements,
        countries
    WHERE
        ST_Contains(countries.wkb_geometry, measurements.geom)
);

CREATE INDEX ON country_measurements USING GIST (geom);

CREATE INDEX ON country_measurements (country);

VACUUM ANALYZE country_measurements;