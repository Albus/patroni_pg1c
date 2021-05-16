FROM albus/baseimage:latest

RUN install_clean postgresql-common python3-pip python3-dev sysstat dpkg-dev python3-psycopg2 mc mosh
RUN pg_conftool -v /etc/postgresql-common/createcluster.conf set create_main_cluster false

WORKDIR /opt/debs/
COPY ./debs/*.deb ./
RUN dpkg-scanpackages . /dev/null > Release
RUN apt-ftparchive packages . > Packages
RUN echo deb [trusted=yes] file:///opt/debs/ ./ > /etc/apt/sources.list.d/local.list
RUN apt -q update --allow-unauthenticated
RUN install_clean --install-recommends postgresql-12=*-1.1C postgresql-server-dev-12=*-1.1C
WORKDIR /root

RUN pip3 config --global set global.disable-pip-version-check true \
  & pip3 config --global set global.no-cache-dir true \
  & pip3 config --global set global.no-color true
RUN pip3 install --upgrade pip wheel setuptools
RUN pip3 install patroni[etcd3] wal-e