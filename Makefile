DB_NAME='gridded-points'
COUNTRIES_DIR='./countries'
VENV_DIR='./.venv'

.PHONY: all create_db load_countries setup_db runserver install_dependencies

all: create_db load_countries setup_db runserver

create_db:
	createdb ${DB_NAME}
	psql ${DB_NAME} -c "CREATE EXTENSION postgis;"

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

setup_db:
	@echo "Preparing database (this can take ~15m)..."
	cat db.sql | psql ${DB_NAME}

.venv/bin/activate:
	@echo "Setting up virtualenv..."
	python3 -m venv .venv

install_dependencies: .venv/bin/activate
	@echo "Installing dependencies..."
	$(VENV_DIR)/bin/pip install -r requirements.txt

runserver: install_dependencies
	DB_NAME=${DB_NAME} $(VENV_DIR)/bin/uvicorn main:app --reload
