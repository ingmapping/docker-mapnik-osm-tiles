FROM ubuntu:16.04
MAINTAINER ingmapping <contact@ingmapping.com>

# Ensure `add-apt-repository` is present
RUN apt-get update -y \
    && apt-get install -y software-properties-common python-software-properties

# Install dependencies 
RUN apt-get update -y \
    && apt-get install -y libboost-all-dev git-core tar unzip wget bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libgeos++-dev libpq-dev libbz2-dev libproj-dev munin-node munin libprotobuf-c0-dev protobuf-c-compiler libfreetype6-dev libpng12-dev libtiff5-dev libicu-dev libgdal-dev libcairo-dev libcairomm-1.0-dev apache2 apache2-dev libagg-dev liblua5.2-dev lua5.1 liblua5.1-dev libgeotiff-epsg postgresql-client-9.5

# Install osm2psql
RUN apt-get update -y \
    && apt-get install -y make cmake g++ libboost-dev libboost-system-dev libboost-filesystem-dev libexpat1-dev zlib1g-dev libbz2-dev libpq-dev libgeos-dev libgeos++-dev libproj-dev lua5.2 liblua5.2-dev

RUN mkdir ~/src \
    && cd ~/src \
    && git clone git://github.com/ingmapping/osm2pgsql.git \
    && cd osm2pgsql \
    && mkdir build && cd build \
    && cmake .. \
    && make \
    && make install 

# Install mapnik library
RUN apt-get install -y autoconf apache2-dev libtool libxml2-dev libbz2-dev libgeos-dev libgeos++-dev libproj-dev gdal-bin libgdal1-dev libmapnik-dev mapnik-utils python-mapnik

# Verify that Mapnik has been installed correctly
RUN python -c 'import mapnik'

# Install the default Mapnik stylesheet (https://github.com/openstreetmap/mapnik-stylesheets)
RUN apt-get install -y subversion
RUN cd ~/src \
    && mkdir ~/src/style \
    && cd ~/src/style \
    && svn co http://svn.openstreetmap.org/applications/rendering/mapnik mapnik-style

# Install the coastline data for the Mapnik stylesheet
RUN cd ~/src/style/mapnik-style \
    && cp osm.xml mapnik-style.xml \
    && ./get-coastlines.sh 
 
# Configure mapnik-stylesheets
RUN cd ~/src/style/mapnik-style/inc && cp fontset-settings.xml.inc.template fontset-settings.xml.inc
ADD mapnik-datasource-settings.sed /tmp/
RUN cd ~/src/style/mapnik-style/inc && sed --file /tmp/mapnik-datasource-settings.sed  datasource-settings.xml.inc.template > datasource-settings.xml.inc
ADD mapnik-settings.sed /tmp/
RUN cd ~/src/style/mapnik-style/inc && sed --file /tmp/mapnik-settings.sed settings.xml.inc.template > settings.xml.inc         

# Install openstreetmap-carto style and additional shapefiles (https://github.com/ingmapping/openstreetmap-carto)
RUN cd ~/src/style \
    && git clone git://github.com/ingmapping/openstreetmap-carto.git \
    && cd openstreetmap-carto \
    && scripts/get-shapefiles.py -s \
    && find ~/src/style/openstreetmap-carto/data \( -type f -iname "*.zip" -o -iname "*.tgz" \) -delete
    
# Install necessary fonts for openstreetmap-carto style
RUN apt-get install -y fonts-noto-cjk fonts-noto-hinted fonts-noto-unhinted ttf-unifont fonts-hanazono

# Install a suitable version of the “carto” compiler
RUN apt-get install -y npm nodejs-legacy \
    && npm install -y -g carto \
    && cd ~/src/style/openstreetmap-carto \
    && carto -v \
    && carto project.mml > openstreetmap-carto.xml
    
# Install osm-bright style (https://github.com/ingmapping/osm-bright)
RUN cd ~/src/style \
    && git clone https://github.com/ingmapping/osm-bright.git \
    && cd osm-bright/osm-bright \
    && sed -e s%unifont%Unifont% -i palette.mss \
    && ln -s ~/src/style/openstreetmap-carto/data ~/src/style/osm-bright/shp

# Download OSM Bright sources and polygons for osm-bright style
RUN cd ~/src/style/osm-bright \
    && chmod a+rx ~/src/style/osm-bright \
    && wget http://data.openstreetmapdata.com/simplified-land-polygons-complete-3857.zip \
    && wget http://data.openstreetmapdata.com/land-polygons-split-3857.zip \
    && wget http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_populated_places_simple.zip

# Unpack the OSM Bright sources and polygons for osm-bright style
RUN cd ~/src/style/osm-bright \ 
    && unzip '*.zip' \ 
    && mkdir osm-bright/shp \
    && mv land-polygons-split-3857 osm-bright/shp \
    && mv simplified-land-polygons-complete-3857 osm-bright/shp \
    && mkdir ne_10m_populated_places_simple \
    && mv ne_10m_populated_places_simple.* ne_10m_populated_places_simple \
    && mv ne_10m_populated_places_simple osm-bright/shp
    

# Create shapeindices for polygons for osm-bright style
RUN cd ~/src/style/osm-bright/osm-bright/shp/land-polygons-split-3857 && shapeindex land_polygons.shp
RUN cd ~/src/style/osm-bright/osm-bright/shp/simplified-land-polygons-complete-3857 && shapeindex simplified_land_polygons.shp

# Configure OSM Bright style sheet for osm-bright style
ADD osm-bright.osm2pgsql.sed /tmp/
RUN cd ~/src/style/osm-bright/osm-bright/ \
    && sed --file /tmp/osm-bright.osm2pgsql.sed --in-place osm-bright.osm2pgsql.mml
ADD configure.py.sed /tmp/
RUN cd ~/src/style/osm-bright/ \
    && sed --file /tmp/configure.py.sed configure.py.sample > configure.py

# Build the OSM Bright style sheet in cartocss 
RUN cd ~/src/style/osm-bright/ \
    && ./make.py

# Build the OSM Bright style sheet in mapnik format
RUN cd ~/src/style/osm-bright/OSMBright/ \
    && carto project.mml > osm-bright.xml  
    
# Install necessary fonts for osm-bright style
RUN npm i npm-font-open-sans --save    
    
# Install openstreets-nl stylesheets and shapefiles 
RUN cd ~/src/style \
    && wget https://ingmapping.com/openstreets-nl/openstreets-nl.zip \
    && unzip openstreets-nl \
    && find ~/src/ \( -type f -iname "*.zip" -o -iname "*.tgz" \) -delete   
    
# Install necessary fonts for openstreets-nl style
RUN apt-get install -y ttf-ubuntu-font-family ttf-dejavu

# Install osm-blossom stylesheets and shapefiles 
RUN cd ~/src \
    && wget https://ingmapping.com/osm-blossom/osm-blossom.zip \
    && unzip osm-blossom \
    && find ~/src/ \( -type f -iname "*.zip" -o -iname "*.tgz" \) -delete
    
# Make local directory for loading OSM data -- this is the place where osm.pbf file should be downloaded to    
RUN mkdir /data
VOLUME /data

ENV PBFFile=europe/netherlands-latest.osm.pbf

ENV MIN_ZOOM=0
ENV MAX_ZOOM=16
ENV REGION=Netherlands

ENV STYLESHEET=openstreetmap-carto 

# mapnik-style / openstreetmap-carto / osm-bright / openstreets-nl / osm-blossom
# mapnik-style.xml / openstreetmap-carto.xml / osm-bright.xml / openstreets-nl.xml / osm-blossom.xml

# Entrypoint and instructions for loading OSM data into postgis database
COPY ./docker-entrypoint.sh /docker-entrypoint.sh 
RUN chmod a+rx /docker-entrypoint.sh 

# Copy files for openstreetmap-carto style
COPY /stylesheets/openstreetmap-carto.xml /root/src/style/openstreetmap-carto/openstreetmap-carto.xml
COPY ./generate_tiles.py /root/src/style/openstreetmap-carto/generate_tiles.py
COPY /viewers/index-openstreetmap-carto.html /root/src/style/openstreetmap-carto/index-openstreetmap-carto.html  

# Copy files for osm-bright style
COPY /stylesheets/osm-bright.xml /root/src/style/osm-bright/osm-bright.xml
COPY ./generate_tiles.py /root/src/style/osm-bright/generate_tiles.py
COPY /viewers/index-osm-bright.html /root/src/style/openstreets-nl/index-osm-bright.html

# Copy files for openstreets-nl style
COPY /stylesheets/openstreets-nl.xml /root/src/style/openstreets-nl/openstreets-nl.xml
COPY ./generate_tiles.py /root/src/style/openstreets-nl/generate_tiles.py   
COPY /viewers/index-openstreets-nl.html /root/src/style/openstreets-nl/index-openstreets-nl.html  

# Copy files for osm-blossom style
COPY /stylesheets/osm-blossom.xml /root/src/style/osm-blossom/osm-blossom.xml
COPY ./generate_tiles.py /root/src/style/osm-blossom/generate_tiles.py   
COPY /viewers/index-osm-blossom.html /root/src/style/osm-blossom/index-osm-blossom.html  

ENV PGPASSWORD=mysecretpassword 
ENV PGUSER=postgres
ENV PGHOST=postgis

ENTRYPOINT /docker-entrypoint.sh



