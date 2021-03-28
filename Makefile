DB_NAME='trace-demo'
COUNTRIES_DIR='./countries'

.PHONY: all create_db load_countries setup_db

all: countries/archive/countries.geojson load_countries setup_db

create_db:
	createdb ${DB_NAME}
	psql ${DB_NAME} -c "CREATE EXTENSION postgis;"

setup_db:
	@echo "Loading countries..."
	cat db.sql | psql ${DB_NAME}

countries/archive/countries.geojson:
	@echo "Fetching countries..."
	wget \
		--no-clobber \
		--directory-prefix=${COUNTRIES_DIR} \
		https://datahub.io/core/geo-countries/r/geo-countries_zip.zip
	unzip \
		-n \
		-d ${COUNTRIES_DIR} \
		$(COUNTRIES_DIR)/geo-countries_zip.zip

load_countries: countries/archive/countries.geojson
	@echo "Loading countries..."
	ogr2ogr \
		-f "PostgreSQL" PG:"dbname=${DB_NAME} user=${USER}" \
	    $(COUNTRIES_DIR)/archive/countries.geojson  \
		-nln countries \
		--config OGR_TRUNCATE YES \
		--config OGR_ENABLE_PARTIAL_REPROJECTION TRUE

clean:
	dropdb ${DB_NAME}