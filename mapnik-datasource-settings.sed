# Perform sed substitutions for `datasource-settings.xml.inc`
s/%(dbname)s/gis/
s/%(password)s/mysecretpassword/
s/%(host)s/postgis/
s/%(estimate_extent)s/false/
s/%(extent)s/344378,6569603,808531,7121368/      
s/<Parameter name="\([^"]*\)">%(\([^)]*\))s<\/Parameter>/<!-- <Parameter name="\1">%(\2)s<\/Parameter> -->/
