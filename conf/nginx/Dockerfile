FROM registry.gitlab.com/trivialsec/containers-common/waf
LABEL org.opencontainers.image.authors="Christopher Langton"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.source="https://gitlab.com/trivialsec/ingress-controller"

ARG BUILD_ENV
ENV BUILD_ENV ${BUILD_ENV}

# Copy config files into the image
COPY .${BUILD_ENV}/rootCA.pem /tmp/rootCA.pem
COPY .${BUILD_ENV}/rootCA.crt /tmp/rootCA.crt
COPY .${BUILD_ENV}/v3.ext /tmp/v3.ext
COPY conf/nginx/entrypoint /entrypoint
COPY conf/certbot/domains-${BUILD_ENV}.txt /tmp/domains.txt
COPY conf/modsec/ /etc/nginx/modsec/
COPY conf/owasp/ /usr/local/owasp-modsecurity-crs/
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx/errors /usr/share/nginx/errors
COPY conf/nginx/conf.d/api-${BUILD_ENV}.conf /etc/nginx/conf.d/api.conf
COPY conf/nginx/conf.d/appserver-${BUILD_ENV}.conf /etc/nginx/conf.d/appserver.conf
COPY conf/nginx/conf.d/assets-${BUILD_ENV}.conf /etc/nginx/conf.d/assets.conf
COPY conf/nginx/conf.d/push-${BUILD_ENV}.conf /etc/nginx/conf.d/push.conf
COPY conf/nginx/conf.d/website-${BUILD_ENV}.conf /etc/nginx/conf.d/website.conf

RUN apk add --no-cache \
    openssl \
    bash \
    curl-dev \
    libmaxminddb-dev \
    libstdc++ \
    libxml2-dev \
    lmdb-dev \
    tzdata \
    yajl && \
    chown -R nginx:nginx /usr/share/nginx

EXPOSE 80 443
ENTRYPOINT ["/entrypoint"]
CMD [ "nginx" ]
