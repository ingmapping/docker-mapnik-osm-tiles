#!/bin/bash

# Check if database "gis" already exists, if not create it
if [ "$( psql -tAc "SELECT 1 FROM pg_database WHERE datname='gis'" )" = '1' ]
then
    echo "Database 'gis' already exists"
else
    echo "Database 'gis' does not exist yet and will be created together with postgis and hstore extensions"
    psql -U ${PGUSER} -h ${PGHOST} -c "CREATE DATABASE gis;"
    psql gis -U ${PGUSER} -h ${PGHOST} -c "ALTER TABLE geometry_columns OWNER TO ${PGUSER};"
    psql gis -U ${PGUSER} -h ${PGHOST} -c "ALTER TABLE spatial_ref_sys OWNER TO ${PGUSER};"
    psql gis -U ${PGUSER} -h ${PGHOST} -c "CREATE EXTENSION postgis;"
    psql gis -U ${PGUSER} -h ${PGHOST} -c "CREATE EXTENSION hstore;"
fi
      
# Downloading OSM europe extract from geofabrik into data folder
if [ ! -f /data/${PBFFile} ]; then
    echo "[MISSING] /data/${PBFFile} file not found! Downloading file and loading data into gis database"
    wget http://download.geofabrik.de/${PBFFile} -O /data/${PBFFile}
else
    echo "[OK] /data/${PBFFile} file"
fi

# Import OSM data inside gis database if not already done
if [ "$( psql -tAc "SELECT 1 FROM pg_tables WHERE schemaname='public' AND tablename='planet_osm_polygon'" )" = '1' ]
then
echo "OSM data is already imported into 'gis' database"
elif [ ${STYLESHEET} == "openstreetmap-carto" ]
then
echo "OSM data does not exist in database, now importing OSM data into 'gis' database"
     osm2pgsql -U ${PGUSER} -H ${PGHOST} -d gis --create --slim  -G --hstore --tag-transform-script ~/src/style/openstreetmap-carto/openstreetmap-carto.lua -C 2500 --number-processes 3 -S ~/src/style/openstreetmap-carto/openstreetmap-carto.style -r .pbf /data/${PBFFile}     
else
echo "OSM data does not exist in database, now importing OSM data into 'gis' database "
   osm2pgsql -U ${PGUSER} -H ${PGHOST} -d gis --create --slim  -G --hstore -C 2500 --number-processes 3 -r .pbf /data/${PBFFile} 
fi

# Mapnik generate tiles settings
export MAPNIK_MAP_FILE=/root/src/style/${STYLESHEET}/${STYLESHEET}.xml      
export MAPNIK_TILE_DIR=/data/tiles
mkdir -p ${MAPNIK_TILE_DIR}
chmod -R 777 ${MAPNIK_TILE_DIR}


# Copy viewer to data folder 
echo "`date +"%Y-%m-%d %H:%M:%S"` Copying leaflet viewer to export data/tiles folder "
cp /root/src/style/${STYLESHEET}/index-${STYLESHEET}.html /data/tiles

# Generate openstreets-nl or osm tiles
echo "`date +"%Y-%m-%d %H:%M:%S"` Generating openstreets-nl or osm tiles in data/tiles folder"
python /root/src/style/${STYLESHEET}/generate_tiles.py







