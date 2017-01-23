# FROM openjdk:8-jre
FROM rastasheep/ubuntu-sshd:latest
MAINTAINER itzg

RUN apt-get update && apt-get install -y --no-install-recommends \
		bzip2 \
		unzip \
		xz-utils \
    software-properties-common \
	&& rm -rf /var/lib/apt/lists/*

# Default to UTF-8 file.encoding
ENV LANG zh_CN.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/jre

RUN set -x \
  && add-apt-repository ppa:openjdk-r/ppa \
	&& apt-get update \
	&& apt-get install -y \
		openjdk-8-jre \
	&& rm -rf /var/lib/apt/lists/* \
	&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
  imagemagick \
  lsof \
  nano \
  sudo \
  vim \
  jq \
  && apt-get clean

RUN useradd -s /bin/false --uid 1000 minecraft \
  && mkdir /data \
  && mkdir /config \
  && mkdir /mods \
  && mkdir /plugins \
  && mkdir /home/minecraft \
  && chown minecraft:minecraft /data /config /mods /plugins /home/minecraft

ENV VERSION 1.1.3
ENV ARCH amd64

# install the chisel http tunnel
WORKDIR /tmp
ENV PATH_NAME chisel_${VERSION}_linux_${ARCH}
RUN wget   -O chisel.tgz https://github.com/jpillora/chisel/releases/download/${VERSION}/${PATH_NAME}.tar.gz
RUN tar -xzvf chisel.tgz ${PATH_NAME}/chisel
RUN mv ${PATH_NAME}/chisel /usr/local/bin

# clean up
RUN rm -rf ${PATH_NAME} /var/lib/apt/lists/*

# add a startup script
COPY forward /usr/local/bin

ADD https://github.com/itzg/restify/releases/download/1.0.3/restify_linux_amd64 /usr/local/bin/restify
COPY start.sh /start
COPY start-minecraft.sh /start-minecraft
COPY mcadmin.jq /usr/share
RUN chmod +x /usr/local/bin/*

VOLUME ["/data","/mods","/config","/plugins","/home/minecraft"]
COPY server.properties /tmp/server.properties
WORKDIR /data

# ENTRYPOINT [ "/start" ]

ENV UID=1000 GID=1000 \
    MOTD="A Minecraft Server Powered by Docker" \
    JVM_OPTS="-Xmx1024M -Xms1024M" \
    TYPE=VANILLA VERSION=LATEST FORGEVERSION=RECOMMENDED LEVEL=world PVP=true DIFFICULTY=easy \
    LEVEL_TYPE=DEFAULT GENERATOR_SETTINGS= WORLD= MODPACK= ONLINE_MODE=TRUE CONSOLE=true

CMD ["/bin/sh", "-c", "/usr/local/bin/forward"]
EXPOSE 8080
