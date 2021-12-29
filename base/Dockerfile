ARG NGINX_VERSION

FROM docker.io/library/nginx:${NGINX_VERSION}-alpine

ARG GEO_DB_RELEASE
ARG MODSEC_BRANCH
ARG OWASP_BRANCH

WORKDIR /opt

RUN chown -R nginx:nginx /usr/share/nginx && \
    echo "Patching..." && \
    apk upgrade --update-cache --available && \
    echo "Installing Dependencies" && \
    apk add --no-cache --virtual general-dependencies \
    autoconf \
    automake \
    byacc \
    curl-dev \
    flex \
    g++ \
    gcc \
    geoip-dev \
    git \
    libc-dev \
    libmaxminddb-dev \
    libstdc++ \
    libtool \
    libxml2-dev \
    linux-headers \
    lmdb-dev \
    make \
    openssl-dev \
    pcre-dev \
    yajl-dev \
    zlib-dev \
    openssl \
    bash \
    tzdata \
    yajl

# /usr/local/modsecurity
RUN echo "Installing ModSec Library" && \
    git clone -b ${MODSEC_BRANCH} --depth 1 https://github.com/SpiderLabs/ModSecurity && \
    git -C /opt/ModSecurity submodule update --init --recursive && \
    (cd "/opt/ModSecurity" && \
        ./build.sh && \
        ./configure --with-lmdb && \
        make && \
        make install \
    ) && \
    rm -fr /opt/ModSecurity \
        /usr/local/modsecurity/lib/libmodsecurity.a \
        /usr/local/modsecurity/lib/libmodsecurity.la

# Clone Modsec Nginx Connector, GeoIP, ModSec OWASP Rules, and download/extract nginx and GeoIP databases
RUN echo 'Cloning Modsec Nginx Connector, GeoIP, ModSec OWASP Rules, and download/extract nginx and GeoIP databases' && \
    git clone -b master --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
    git clone -b master --depth 1 https://github.com/leev/ngx_http_geoip2_module.git && \
    git clone -b ${OWASP_BRANCH} --depth 1 https://github.com/coreruleset/coreruleset.git /usr/local/owasp-modsecurity-crs && \
    wget -O - https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | tar -xz && \
    mkdir -p /etc/nginx/geoip && \
    wget -O - https://download.db-ip.com/free/dbip-city-lite-${GEO_DB_RELEASE}.mmdb.gz | gzip -d > /etc/nginx/geoip/dbip-city-lite.mmdb && \
    wget -O - https://download.db-ip.com/free/dbip-country-lite-${GEO_DB_RELEASE}.mmdb.gz | gzip -d > /etc/nginx/geoip/dbip-country-lite.mmdb

# Install GeoIP2 and ModSecurity Nginx modules
RUN echo 'Installing Nginx Modules' && \
    (cd "/opt/nginx-$NGINX_VERSION" && \
        ./configure --with-compat \
            --add-dynamic-module=../ModSecurity-nginx \
            --add-dynamic-module=../ngx_http_geoip2_module && \
        make modules \
    ) && \
    cp /opt/nginx-$NGINX_VERSION/objs/ngx_http_modsecurity_module.so \
        /opt/nginx-$NGINX_VERSION/objs/ngx_http_geoip2_module.so \
        /usr/lib/nginx/modules/ && \
    rm -fr /opt/* && \
    apk del general-dependencies

EXPOSE 80 443
ENTRYPOINT ["/entrypoint"]
CMD [ "nginx" ]
