FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    libgl1 \
    libgles2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY builds/Server/dead_zones_server.x86_64 ./dead_zones_server
COPY builds/Server/dead_zones_server.pck ./dead_zones_server.pck

RUN chmod +x ./dead_zones_server

EXPOSE 9080

CMD ["./dead_zones_server", "--headless", "--", "--server", "--port", "9080"]
