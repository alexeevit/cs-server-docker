FROM --platform=linux/amd64 cm2network/steamcmd:latest

ARG STEAM_USER=anonymous
ARG STEAM_PASSWORD=
ARG METAMOD_VERSION=1.3.0.138
ARG AMXMOD_VERSION=1.8.2
ARG REHLDS_VERSION=3.13.0.788
ARG REUNION_VERSION=0.1.0.92d

ENV CPU_MHZ=2000

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

# Install HLDS
RUN curl -sLJO "https://dl.rehlds.ru/hlds/hlds_linux_8684.zip" && \
    unzip hlds_linux_8684.zip -d /home/steam/hlds && \
    rm -rf hlds_linux_8684.zip

RUN chmod +x /home/steam/hlds/hlds_run && \
    chmod +x /home/steam/hlds/hlds_linux

RUN mkdir -p ~/.steam && ln -s /home/steam/hlds ~/.steam/sdk32
RUN ln -s /home/steam/steamcmd/ /home/steam/hlds/steamcmd
COPY --chown=steam:steam steam_appid.txt /home/steam/hlds/steam_appid.txt
COPY --chown=steam:steam --chmod=755 hlds_run.sh /home/steam/hlds/hlds_run.sh

# Install ReHLDS
RUN curl -sLJO "https://github.com/dreamstalker/rehlds/releases/download/$REHLDS_VERSION/rehlds-bin-$REHLDS_VERSION.zip" \
    && unzip "rehlds-bin-$REHLDS_VERSION.zip" -d "/home/steam/rehlds" \
    && cp -R /home/steam/rehlds/bin/linux32/* /home/steam/hlds/ \
    && rm -rf "rehlds-bin-$REHLDS_VERSION.zip" "/home/steam/rehlds"

# Install Metamod-r
RUN curl -sLJO "https://github.com/theAsmodai/metamod-r/releases/download/$METAMOD_VERSION/metamod-bin-$METAMOD_VERSION.zip" \
    && unzip "metamod-bin-$METAMOD_VERSION.zip" -d "/home/steam/metamod" \
    && cp -R /home/steam/metamod/addons /home/steam/hlds/cstrike/ \
    && rm -rf "metamod-bin-$METAMOD_VERSION.zip" "/home/steam/metamod" \
    && touch /home/steam/hlds/cstrike/addons/metamod/plugins.ini \
    && sed -i 's/dlls\/cs\.so/addons\/metamod\/metamod_i386\.so/g' /home/steam/hlds/cstrike/liblist.gam

# Install AMX mod X
RUN curl -sqL "https://www.amxmodx.org/amxxdrop/1.9/amxmodx-1.9.0-git5294-base-linux.tar.gz" | tar -C /home/steam/hlds/cstrike/ -zxvf - \
    && curl -sqL "https://www.amxmodx.org/amxxdrop/1.9/amxmodx-1.9.0-git5294-cstrike-linux.tar.gz" | tar -C /home/steam/hlds/cstrike/ -zxvf - \
    && cat /home/steam/hlds/cstrike/mapcycle.txt >> /home/steam/hlds/cstrike/addons/amxmodx/configs/maps.ini \
    && echo 'linux addons/amxmodx/dlls/amxmodx_mm_i386.so' >> /home/steam/hlds/cstrike/addons/metamod/plugins.ini

RUN curl -sLJO "https://dl.rehlds.ru/metamod/Reunion/reunion_$REUNION_VERSION.zip" && \
    unzip "reunion_$REUNION_VERSION.zip" -d reunion && \
    mkdir -p /home/steam/hlds/cstrike/addons/reunion && \
    cp reunion/bin/Linux/reunion_mm_i386.so /home/steam/hlds/cstrike/addons/reunion/reunion_mm_i386.so && \
    cp reunion/reunion.cfg /home/steam/hlds/cstrike/reunion.cfg && \
    cp reunion/amxx/* /home/steam/hlds/cstrike/addons/amxmodx/scripting/ && \
    echo 'linux addons/reunion/reunion_mm_i386.so' >> /home/steam/hlds/cstrike/addons/metamod/plugins.ini && \
    sed -i 's/Setti_Prefix1 = 5/Setti_Prefix1 = 4/g' /home/steam/hlds/cstrike/reunion.cfg && \
    rm -rf reunion_$REUNION_VERSION.zip reunion

RUN curl -sLJO "https://github.com/APGRoboCop/podbot_mm/releases/download/V3B24-APG/podbot_full_V3B24.zip" && \
    unzip podbot_full_V3B24.zip -d /home/steam/hlds/cstrike/addons && \
    echo 'linux addons/podbot/podbot_mm.so' >> /home/steam/hlds/cstrike/addons/metamod/plugins.ini && \
    rm -rf podbot_full_V3B24.zip

COPY --chown=steam:steam server.cfg /home/steam/hlds/cstrike/server.cfg

# Dump default maps
RUN mkdir /home/steam/hlds/cstrike/maps.original && \
    cp -rf /home/steam/hlds/cstrike/maps/* /home/steam/hlds/cstrike/maps.original

# Add maps
# ADD maps/* /opt/hlds/cstrike/maps/
# ADD files/mapcycle.txt /opt/hlds/cstrike/mapcycle.txt

WORKDIR /home/steam/hlds
CMD ["/home/steam/hlds/hlds_run.sh"]
