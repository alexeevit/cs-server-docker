# README

It's a simple CS 1.6 server wrapped into a docker image.

DockerHub: [alexeev/cs-server](https://hub.docker.com/repository/docker/alexeev/cs-server/general)

## Run

```
docker run -d -v <your local maps dir>:/home/steam/hlds/cstrike/maps -p 27015:27015/udp -e START_MAP=de_dust2 -e ADMIN_STEAM=<your steam id> -e SERVER_NAME="My Server" --name=cs-server alexeev/cs-server:rehlds
```
