FROM tomcat:8.0.24-jre8
MAINTAINER jaehue@jang.io

ENV TOMCAT_USER dspace
ENV DS_VERSION=5.2

RUN useradd -m dspace
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu
RUN curl -SsL https://github.com/DSpace/DSpace/archive/dspace-$DS_VERSION.tar.gz | tar -C /usr/src/ -xzf -
RUN mkdir /dspace && chown -R dspace /dspace /usr/src/DSpace-dspace-$DS_VERSION
RUN buildDep=" \
        git \
        maven \
        openjdk-7-jdk \
    "; apt-get update && apt-get install -y $buildDep \
    && cd /usr/src/DSpace-dspace-$DS_VERSION \
    && sed -i "s/path=\"Mirage\/\"/path=\"Mirage2\/\"/" /usr/src/DSpace-dspace-$DS_VERSION/dspace/config/xmlui.xconf \
    && su dspace -c 'mvn package -Dmirage2.on=true' \
    && sed -i "s/<java classname=\"org.dspace.storage.rdbms.DatabaseUtils\" classpathref=\"class.path\" fork=\"yes\" failonerror=\"yes\">/<java classname=\"org.dspace.storage.rdbms.DatabaseUtils\" classpathref=\"class.path\" fork=\"yes\" failonerror=\"no\">/" /usr/src/DSpace-dspace-$DS_VERSION/dspace/target/dspace-installer/build.xml \
    && cd dspace/target/dspace-installer \
    && gosu dspace ant fresh_install \
    && cd /dspace \
    && rm -r /usr/src/* \
    && apt-get purge -y --auto-remove $buildDep && rm -rf /var/lib/apt/lists/* /tmp/*
