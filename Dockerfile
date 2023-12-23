FROM --platform=linux/amd64 cm2network/steamcmd:latest

ARG STEAM_USER=anonymous
ARG STEAM_PASSWORD=
ARG METAMOD_VERSION=1.21.1-am
ARG AMXMOD_VERSION=1.8.2

ENV CPU_MHZ=2000

# Install HLDS
RUN mkdir -p /home/steam/hlds
RUN /home/steam/steamcmd/steamcmd.sh +force_install_dir /home/steam/hlds +login $STEAM_USER $STEAM_PASSWORD +app_update 90 validate +quit || :
RUN /home/steam/steamcmd/steamcmd.sh +force_install_dir /home/steam/hlds +login $STEAM_USER $STEAM_PASSWORD +app_update 70 validate +quit || :
RUN /home/steam/steamcmd/steamcmd.sh +force_install_dir /home/steam/hlds +login $STEAM_USER $STEAM_PASSWORD +app_update 10 validate +quit || :
RUN /home/steam/steamcmd/steamcmd.sh +force_install_dir /home/steam/hlds +login $STEAM_USER $STEAM_PASSWORD +app_update 90 validate +quit

USER root

RUN dpkg --add-architecture i386
RUN apt-get update -qq && apt-get install -yq \
  libcurl4:i386 \
  unzip \
  gdb \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

USER steam

# Install metamod
RUN curl -sqLO "https://www.amxmodx.org/release/metamod-$METAMOD_VERSION.zip" && \
    unzip "metamod-$METAMOD_VERSION.zip" -d /home/steam/hlds/cstrike/ && \
    rm "metamod-$METAMOD_VERSION.zip"
COPY --chown=steam:steam metamod/liblist.gam /home/steam/hlds/cstrike/liblist.gam
COPY --chown=steam:steam metamod/plugins.ini /home/steam/hlds/cstrike/addons/metamod/plugins.ini

# Install dproto
RUN mkdir -p /home/steam/hlds/cstrike/addons/dproto
COPY --chown=steam:steam dproto-0.4.8p/dproto_i386.so /home/steam/hlds/cstrike/addons/dproto/dproto_i386.so
COPY --chown=steam:steam dproto-0.4.8p/dproto.cfg /home/steam/hlds/cstrike/dproto.cfg

# Install AMX mod X
RUN curl -sqL "http://www.amxmodx.org/release/amxmodx-$AMXMOD_VERSION-base-linux.tar.gz" | tar -C /home/steam/hlds/cstrike/ -zxvf -
RUN curl -sqL "http://www.amxmodx.org/release/amxmodx-$AMXMOD_VERSION-cstrike-linux.tar.gz" | tar -C /home/steam/hlds/cstrike/ -zxvf -

RUN mkdir -p ~/.steam && ln -s /home/steam/hlds ~/.steam/sdk32
RUN ln -s /home/steam/steamcmd/ /home/steam/hlds/steamcmd
COPY --chown=steam:steam steam_appid.txt /home/steam/hlds/steam_appid.txt
COPY --chown=steam:steam --chmod=755 hlds_run.sh /home/steam/hlds/hlds_run.sh

COPY --chown=steam:steam server.cfg /home/steam/hlds/cstrike/server.cfg

# Add maps
# ADD maps/* /opt/hlds/cstrike/maps/
# ADD files/mapcycle.txt /opt/hlds/cstrike/mapcycle.txt

WORKDIR /home/steam/hlds
CMD ["/home/steam/hlds/hlds_run.sh"]
