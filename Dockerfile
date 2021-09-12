# CUSTOM base image that supports arm
FROM phusion/baseimage:focal-1.0.0-arm64
ENV SEAFILE_SERVER=seafile-server SEAFILE_VERSION=8.0.7

RUN apt-get update --fix-missing

# Utility tools
RUN apt-get install -y vim htop net-tools psmisc wget curl git

# For suport set local time zone.
RUN export DEBIAN_FRONTEND=noninteractive && apt-get install tzdata -y

# Nginx
RUN apt-get install -y nginx

# CUSTOM install Pillow dependencies and libmemcached
RUN apt-get install -y libtiff5-dev libjpeg8-dev libopenjp2-7-dev zlib1g-dev \
    libfreetype6-dev liblcms2-dev libwebp-dev tcl8.6-dev tk8.6-dev python3-tk \
    libharfbuzz-dev libfribidi-dev libxcb1-dev libmemcached-dev libmariadbclient-dev

# Python3
RUN apt-get install -y python3 python3-pip python3-setuptools
RUN python3 -m pip install --upgrade pip && rm -r /root/.cache/pip

RUN pip3 install --timeout=3600 click termcolor colorlog pymysql gunicorn mysqlclient\
    django==1.11.29 && rm -r /root/.cache/pip

RUN pip3 install --timeout=3600 Pillow pylibmc captcha jinja2 \
    sqlalchemy django-pylibmc django-simple-captcha && \
    rm -r /root/.cache/pip

# CUSTOM full path to directories
COPY seafile-docker/scripts_8.0/ /scripts
COPY seafile-docker/image/seafile_8.0//templates /templates
COPY seafile-docker/image/seafile_8.0/services /services
RUN chmod u+x /scripts/*

RUN mkdir -p /etc/my_init.d && \
    rm -f /etc/my_init.d/* && \
    cp /scripts/create_data_links.sh /etc/my_init.d/01_create_data_links.sh

RUN mkdir -p /etc/service/nginx && \
    rm -f /etc/nginx/sites-enabled/* /etc/nginx/conf.d/* && \
    mv /services/nginx.conf /etc/nginx/nginx.conf && \
    mv /services/nginx.sh /etc/service/nginx/run

# Seafile
WORKDIR /opt/seafile

# CUSTOM download arm build
RUN mkdir -p /opt/seafile/ && cd /opt/seafile/ && \
    wget https://github.com/haiwen/seafile-rpi/releases/download/v${SEAFILE_VERSION}/seafile-server-${SEAFILE_VERSION}-focal-arm64v8.tar.gz && \
    tar -zxvf seafile-server-${SEAFILE_VERSION}-focal-arm64v8.tar.gz && \
    rm -f seafile-server-${SEAFILE_VERSION}-focal-arm64v8.tar.gz

# For using TLS connection to LDAP/AD server with docker-ce.
RUN find /opt/seafile/ \( -name "liblber-*" -o -name "libldap-*" -o -name "libldap_r*" -o -name "libsasl2.so*" \) -delete

EXPOSE 80

CMD ["/sbin/my_init", "--", "/scripts/start.py"]
