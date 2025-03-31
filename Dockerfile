FROM eclipse-temurin:17-jdk as runner

WORKDIR /app

# Hämta den förbyggda JAR-filen
RUN wget https://github.com/graphhopper/graphhopper/releases/download/10.2/graphhopper-web-10.2.jar -O graphhopper-web.jar



# Hämta OSM-filen
RUN wget https://github.com/lundopendata/graphhopper/raw/refs/heads/playground/skane.osm.pbf

RUN wget https://raw.githubusercontent.com/lundopendata/graphhopper/refs/heads/playground/core/src/main/resources/com/graphhopper/custom_models/carf.json

# Hämta konfigurationsfilen
RUN wget https://raw.githubusercontent.com/lundopendata/graphhopper/refs/heads/playground/config.yml

# Exponera API-porten
EXPOSE 8989

# Bygg GraphHopper's graph med både OSM och GTFS under byggprocessen
RUN java -Xmx4g -Xms4g \
    -Ddw.graphhopper.datareader.file=skane.osm.pbf \
    -jar graphhopper-web.jar import config.yml

# Starta endast webbtjänsten när containern startas
CMD ["java", "-Xmx4g", "-Xms4g", "-jar", "/app/graphhopper-web.jar", "server", "config.yml"]