DB_NAME=trace-demo

log () {
  local bold=$(tput bold)
  local normal=$(tput sgr0)
  echo "${bold}${1}${normal}" 1>&2;
}

log "Creating db $DB_NAME..."
createdb $DB_NAME

log "Download countries..."
curl \
    -L \
    --create-dirs \
    --output countries/geo-countries_zip.zip \
    https://datahub.io/core/geo-countries/r/geo-countries_zip.zip
unzip countries/geo-countries_zip.zip -d countries

log "Inserting countries into db $DB_NAME..."
OGR_ENABLE_PARTIAL_REPROJECTION=TRUE ogr2ogr \
    -f "PostgreSQL" PG:"dbname=$DB_NAME user=$USER" "countries/archive/countries.geojson"  \
    -nln countries \
    -s_srs EPSG:4326 \
    -t_srs EPSG:3857 

log "Setting up db $DB_NAME..."
cat db.sql | psql $DB_NAME
