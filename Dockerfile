FROM eclipse-temurin:17-jdk as builder

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y git maven && rm -rf /var/lib/apt/lists/*

# Clone GraphHopper repository
RUN git clone --depth 1 --single-branch --branch playground https://github.com/lundopendata/graphhopper.git 

# Set correct working directory
WORKDIR /app/graphhopper

# Build all modules first to resolve dependencies
RUN mvn clean install -DskipTests

# Then, build just the web module
RUN mvn --projects web package -DskipTests

# Create final runtime image
FROM nginx:alpine as runner

WORKDIR /app

# Kopiera Nginx-konfigurationen
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Kopiera GraphHopper JAR från byggsteget
COPY --from=builder /app/graphhopper/web/target/graphhopper-web-*.jar /app/graphhopper-web.jar

# Kopiera config.yml
RUN wget https://raw.githubusercontent.com/lundopendata/graphhopper/refs/heads/playground/config.yml

# Kopiera OSM-data
RUN wget https://download.geofabrik.de/europe/sweden-latest.osm.pbf

# Expose API port
EXPOSE 80

# Starta både GraphHopper och Nginx
CMD sh -c "java -Xmx4g -Xms4g -Ddw.graphhopper.datareader.file=sweden-latest.osm.pbf -jar /app/graphhopper-web.jar import config.yml & nginx -g 'daemon off;'"


