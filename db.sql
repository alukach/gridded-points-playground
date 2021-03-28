CREATE EXTENSION postgis;

DROP TABLE IF EXISTS measurements;

-- Set seed so random data is same every time we run this
SET
    seed TO 1;

CREATE TABLE measurements (
    id SERIAL PRIMARY KEY,
    val INTEGER,
    geom GEOMETRY(POINT, 3857),
    country TEXT
);

INSERT INTO
    measurements (geom, country, val)
SELECT
    -- Generate 0-100k random points between for every country
    (
        ST_Dump(
            ST_GeneratePoints(wkb_geometry, (random() * 10000) :: int)
        )
    ).geom,
    iso_a3 AS country,
    random() * 10000 AS val
FROM
    countries;

VACUUM ANALYZE measurements;