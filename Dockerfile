FROM registry.gitlab.com/trivialsec/containers-common/waf
LABEL org.opencontainers.image.authors="Christopher Langton"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.source="https://gitlab.com/trivialsec/ingress-controller"

ARG BUILD_ENV
ENV BUILD_ENV ${BUILD_ENV}

# Copy config files into the image
COPY .${BUILD_ENV}/entrypoint /entrypoint
COPY .${BUILD_ENV}/modsec/ /etc/nginx/modsec/
COPY .${BUILD_ENV}/owasp/ /usr/local/owasp-modsecurity-crs/
COPY .${BUILD_ENV}/nginx.conf /etc/nginx/nginx.conf
COPY .${BUILD_ENV}/errors /usr/share/nginx/errors
COPY .${BUILD_ENV}/conf.d /etc/nginx/conf.d
COPY .${BUILD_ENV}/options-ssl-nginx.conf /etc/nginx/options-ssl-nginx.conf
COPY .${BUILD_ENV}/ssl-dhparams.pem /etc/nginx/ssl-dhparams.pem
COPY .${BUILD_ENV}/certs /etc/nginx/certs

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
