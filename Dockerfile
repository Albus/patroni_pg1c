FROM albus/baseimage:master

COPY ./debs/*.deb /opt/debs/

RUN install_clean postgresql-common python3-pip python3-dev sysstat dpkg-dev python3-psycopg2 mc mosh fish htop lsof strace pwgen
RUN pg_conftool -v /etc/postgresql-common/createcluster.conf set create_main_cluster false \
    pg_conftool -v /etc/postgresql-common/createcluster.conf set ssl off

WORKDIR /opt/debs
RUN dpkg-scanpackages . /dev/null > /opt/debs/Release
RUN apt-ftparchive packages ./ > /opt/debs/Packages

WORKDIR /tmp
RUN echo deb [trusted=yes] file:///opt/debs/ ./ > /etc/apt/sources.list.d/local.list
RUN apt update --allow-unauthenticated

RUN install_clean --install-recommends \
    ^postgresql-client-1[2-3]{1}$=*-1.1C \
    ^postgresql-1[2-3]{1}$=*-1.1C \
    ^postgresql-server-dev-1[2-3]{1}$=*-1.1C

RUN apt-mark hold `find /opt/debs -iname "*.deb" -exec dpkg-deb --field {} package \; | xargs` || true
RUN usermod -u 1100 postgres & groupmod -g 1100 postgres \
  & chown 1100:1100 -hR /var/lib/postgresql /var/run/postgresql /etc/postgresql \
  & find / -group 109 -exec chgrp -h 1100 {} \; 2>/dev/null || true \
  & find / -user 106 -exec chown -h 1100 {} \; 2>/dev/null || true
RUN python -m pip config --global set global.disable-pip-version-check true \
  & python -m pip config --global set global.no-cache-dir true \
  & python -m pip config --global set global.no-color true

#VOLUME /var/lib/postgresql

RUN python -m pip install --upgrade --compile --prefer-binary patroni[raft]

WORKDIR /var/lib/postgresql

EXPOSE 5432/tcp 22/tcp
STOPSIGNAL SIGTERM
