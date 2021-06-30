FROM docker.io/certbot/certbot:latest

LABEL org.opencontainers.image.authors="Christopher Langton"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.source="https://gitlab.com/trivialsec/ingress-controller"
ARG BUILD_ENV
ENV BUILD_ENV ${BUILD_ENV}
ENV CERTBOT_STAGING ${CERTBOT_STAGING:-'0'}

WORKDIR /tmp
RUN echo "Patching..." && \
    apk upgrade --update-cache --available && \
    apk add bash && \
    rm -rf /tmp/* /var/cache/apk/*

COPY conf/certbot/options-ssl-nginx.conf .
COPY conf/certbot/ssl-dhparams.pem .
COPY conf/certbot/domains-${BUILD_ENV}.txt domains.txt
COPY conf/certbot/entrypoint /entrypoint

ENTRYPOINT ["/entrypoint"]
CMD [ "certbot", "renew" ]
