FROM eclipse-temurin:17-jdk as builder

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y git maven && rm -rf /var/lib/apt/lists/*

# Clone GraphHopper repository
RUN git clone --depth 1 --single-branch --branch gtfs https://github.com/lundopendata/graphhopper.git 

# Set correct working directory
WORKDIR /app/graphhopper

# Build all modules first to resolve dependencies
RUN mvn clean install -DskipTests

# Then, build just the web module
RUN mvn --projects web package -DskipTests

# Create final runtime image
FROM eclipse-temurin:17-jdk as runner

WORKDIR /app

# Copy built JAR file from builder stage
COPY --from=builder /app/graphhopper/web/target/graphhopper-web-*.jar /app/graphhopper-web.jar

# Copy config file
# COPY config.yml .
RUN wget https://raw.githubusercontent.com/lundopendata/graphhopper/refs/heads/gtfs/config.yml

# ARG GTFS_API_KEY
ARG GTFS_API_KEY
ENV GTFS_API_KEY=${GTFS_API_KEY}
RUN wget --header="Accept-Encoding: gzip, deflate" -O sweden.zip "https://opendata.samtrafiken.se/gtfs-sweden/sweden.zip?key=${GTFS_API_KEY}"

RUN wget https://download.geofabrik.de/europe/sweden-latest.osm.pbf


# Expose API port
EXPOSE 8989

# Bygg GraphHopper's graph med både OSM och GTFS under byggprocessen
RUN java -Xmx4g -Xms4g \
    -Ddw.graphhopper.datareader.file=sweden-latest.osm.pbf \
    -Ddw.graphhopper.gtfs.file=sweden.zip \
    -jar graphhopper-web.jar import config.yml

# Starta endast webbtjänsten när containern startas
CMD ["java", "-Xmx4g", "-Xms4g", "-jar", "/app/graphhopper-web.jar", "server", "config.yml"]


