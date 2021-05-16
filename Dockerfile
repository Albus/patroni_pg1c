FROM albus/baseimage:latest
COPY ./debs/*.deb /opt/debs/

RUN install_clean postgresql-common python3-pip python3-dev sysstat dpkg-dev python3-psycopg2 mc mosh
RUN pg_conftool -v /etc/postgresql-common/createcluster.conf set create_main_cluster false

WORKDIR /opt/debs
RUN dpkg-scanpackages . /dev/null > /opt/debs/Release
RUN apt-ftparchive packages ./ > /opt/debs/Packages

WORKDIR /tmp
RUN echo deb [trusted=yes] file:///opt/debs/ ./ > /etc/apt/sources.list.d/local.list
RUN apt update --allow-unauthenticated
RUN install_clean --install-recommends postgresql-12=*-1.1C postgresql-server-dev-12=*-1.1C
RUN apt-mark hold `find /opt/debs -iname "*.deb" -exec dpkg-deb --field {} package \; | xargs` || true
RUN usermod -u 1100 postgres & groupmod -g 1100 postgres \
  & chown 1100:1100 -hR /var/lib/postgresql /var/run/postgresql /etc/postgresql \
  & find / -group 109 -exec chgrp -h 1100 {} \; 2>/dev/null || true \
  & find / -user 106 -exec chown -h 1100 {} \; 2>/dev/null || true
RUN pip3 config --global set global.disable-pip-version-check true \
  & pip3 config --global set global.no-cache-dir true \
  & pip3 config --global set global.no-color true
RUN pip3 install --upgrade pip wheel setuptools
RUN pip3 install patroni[etcd3] wal-e

USER postgres
VOLUME /var/lib/postgresql
RUN ssh-import-id -o ~postgres/.ssh/authorized_keys gh:albus

USER root

EXPOSE 5432/tcp 22/tcp
STOPSIGNAL SIGTERM