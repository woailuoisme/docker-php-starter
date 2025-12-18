FROM jiaoio/php-base-cli-xdebug
ENV VERSION=1.10.1 \
 FRANKENPHP_VERSION=1.10.1
COPY download-frankenphp.sh /usr/local/bin/download-frankenphp.sh
RUN chmod +x /usr/local/bin/download-frankenphp.sh \
    && /usr/local/bin/download-frankenphp.sh \
    && frankenphp --version
