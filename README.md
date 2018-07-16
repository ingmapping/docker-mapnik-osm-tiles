# docker-mapnik-osm-tiles
Dockerized project for generating raster tiles from OSM vector data

## Introduction  

This project is part of an internship assignment which aimed at creating tiled basemaps for the KNMI geospatial infrastructure. The data and tools used to create the osm basemap are open-source. Therefore, this project is reproducible for everyone who wants to create simple basemaps (raster tiled basemaps) from free vector data! This repository contains all the necessary instructions and files to generate osm tiles with Mapnik and a generate_tiles.py script inside a docker container. 

This directory contains instructions to generate custom osm tiles with Mapnik generate_tiles.py script inside a docker container. This docker is a solution for anyone who wants to pre-generate raster tiles instead of using a tileserver. There are many other docker projects available with renderd and mod_tile following the steps of [switch2osm]https://switch2osm.org/manually-building-a-tile-server-16-04-2-lts/)

## How to set up docker-postgis for use with docker-mapnik-osm-tiles

The docker-postgis image can be built by pulling the image from Docker Hub:

```
docker pull ingmapping/postgis
```
or from source:

```
docker build -t ingmapping/postgis git://github.com/ingmapping/docker-postgis
```

After buidling the postgis image, first create a network (e.g. "foo") to be able to link both containers (docker-postgis & docker-mapnik-osm-tiles): 

```
docker network create foo
```

Then, run the postgis container:

```
docker run --name postgis -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=mysecretpassword -e POSTGRES_DBNAME=gis -p 5432:5432 --net foo -d ingmapping/postgis
```

You might need to start the postgis container with the following command:

```
docker start postgis
```

To inspect the created network "foo":

```
docker network inspect foo
```

## How to set up docker-mapnik-osm-tiles

Can be built from the Dockerfile:

```
docker build -t ingmapping/docker-mapnik-osm-tiles github.com/ingmapping/docker-mapnik-osm-tiles.git
```

or pulled from Docker Hub:

```
docker pull ingmapping/docker-mapnik-osm-tiles
```

## How to run docker-mapnik-osm-tiles
To run the container, replace 'pwd' by your current working directory (the directory where you want the tiles to be exported) and use the following command:

```
docker run -i -t --rm --name docker-mapnik-osm-tiles --net foo -v 'pwd'/:/data ingmapping/docker-mapnik-osm-tiles
```

The above command will generate osmm tiles for zoomlevel 0 to 16 in a folder called 'tiles'. If you want to generate osm tiles for other zoom levels you can use the environement variables "MIN_ZOOM" and "MAX_ZOOM". For example, for zoom level 3 to 4:

```
docker run -i -t --rm --name docker-mapnik-osm-tiles --net foo -v 'pwd'/:/data -e MIN_ZOOM=3 -e MAX_ZOOM=14 ingmapping/docker-mapnik-osm-tiles
```

How to remove your exported tiles if permission problems: 

If the tiles are created by root inside the Docker container it can cause problems when you want to remove your tiles locally on the host with a non-root user. A solution how to remove the files is to run another docker container:

```
docker run -it --rm -v 'pwd'/:/mnt:z phusion/baseimage bash 
cd mnt 
rm -rf tiles 
exit
```

## How to use/view your generated osm tiles

Once that you have your tiles exported in a folder directory structure, you can use/view the generated raster tiles using various JavaScript mapping libraries. For example:

* [Leaflet JS](https://leafletjs.com/) is a lightweight open source JavaScript library for building interactive web maps.

```js
	L.tileLayer('file:////PATH-TO-YOUR-TILES-DIRECTORY-HERE/{z}/{x}/{y}.png', {
		minZoom: 5, maxZoom: 16,
		attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors | <a href="https://github.com/ingmapping/docker-mapnik-osm-tiles/"> docker-mapnik-osm-tiles project </a> - <a href="https://www.ingmapping.com">ingmapping.com</a>'
	}).addTo(map);
```

