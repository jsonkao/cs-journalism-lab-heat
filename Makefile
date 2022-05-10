visuals/static/census.topojson: mapping/census.geojson Makefile
	mapshaper $< \
	-filter-fields GEOID,temp,temp_past,tree,imp,income,builtfar,residfar \
	-simplify 22% \
	-clean \
	-o $@ format=topojson

mapping/census.geojson: mapping/tl_2021_36_tabblock20/tl_2021_36_tabblock20.shp visuals/static/temp_dev.csv
	mapshaper $< \
	-filter "['047', '081', '061', '005', '/* 085 */'].includes(COUNTYFP20)" \
	-rename-fields GEOID=GEOID20,ALAND=ALAND20 \
	-filter "ALAND > 0" \
	-filter-fields GEOID \
	-join $(word 2,$^) keys=GEOID,GEOID string-fields=GEOID \
	-o bbox $@

mapping/tl_2021_36_tabblock20/tl_2021_36_tabblock20.shp: mapping/tl_2021_36_tabblock20.zip
	unzip -d $(dir $@) $<
	touch $@