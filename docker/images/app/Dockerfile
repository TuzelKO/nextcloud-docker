# Nextcloud docker image
# Based on Alpine Linux
FROM alpine:3.23

# Maintainer
LABEL maintainer="Eugene Frost"

# Build settings
ARG USER_UID=1001
ARG USER_GID=1001
ARG PHP_VERSION=85

# Create user and group
RUN addgroup -g ${USER_GID} app && adduser -D -h /home/app -s /bin/sh -u ${USER_UID} -G app app

# Install software
RUN apk update && apk upgrade && apk add \
        musl-locales \
        musl-locales-lang \
        git \
        wget \
        unzip \
        py3-setuptools \
        ca-certificates \
        supervisor \
        unit \
        unit-php${PHP_VERSION} \
        php${PHP_VERSION} \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-ctype \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-dom \
        php${PHP_VERSION}-embed \
        php${PHP_VERSION}-exif \
        php${PHP_VERSION}-fileinfo \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-gmp \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-iconv \
        php${PHP_VERSION}-json \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-pcntl \
        php${PHP_VERSION}-pdo \
        php${PHP_VERSION}-pdo_mysql \
        php${PHP_VERSION}-pdo_pgsql \
        php${PHP_VERSION}-pdo_sqlite \
        php${PHP_VERSION}-pecl-apcu \
        php${PHP_VERSION}-pecl-imagick \
        imagemagick \
        imagemagick-heic \
        imagemagick-jpeg \
        imagemagick-pdf \
        imagemagick-svg \
        imagemagick-tiff \
        imagemagick-webp \
        php${PHP_VERSION}-pecl-memcached \
        php${PHP_VERSION}-pecl-redis \
        php${PHP_VERSION}-phar \
        php${PHP_VERSION}-posix \
        php${PHP_VERSION}-simplexml \
        php${PHP_VERSION}-sodium \
        php${PHP_VERSION}-sysvsem \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-xmlreader \
        php${PHP_VERSION}-xmlwriter \
        php${PHP_VERSION}-zip \
    && rm -rf /var/cache/apk/*


# Create php symbolic link
RUN ln -s /usr/bin/php${PHP_VERSION} /usr/bin/php

# Set environments
ENV LANG=ru_RU.UTF-8
ENV LC_ALL=ru_RU.UTF-8

# Create and fill supervisor configs dir
RUN rm -rf /etc/supervisor && mkdir -p /etc/supervisor
ADD ./etc/supervisor /etc/supervisor
RUN chown -R app:app /etc/supervisor

# Set own rules on supervisor working dirs
RUN mkdir -p /run/supervisord && chown -R app:app /run/supervisord
RUN mkdir -p /var/lib/supervisord && chown -R app:app /var/lib/supervisord
RUN mkdir -p /var/log/supervisord && chown -R app:app /var/log/supervisord

# Create and fill unit configs dir
RUN rm -rf /etc/unit && mkdir -p /etc/unit
ADD ./etc/unit /etc/unit
RUN chown -R app:app /etc/unit

# Add php config overrides
ADD ./etc/php/ /etc/php${PHP_VERSION}/

# Set own rules on unit working dirs
RUN mkdir -p /run/unit && chown -R app:app /run/unit

# Create tmp placeholder
RUN ln -s /tmp /usr/tmp

# Add entrypoint scripts
ADD ./bin/docker-entrypoint.sh /bin/docker-entrypoint.sh
RUN chmod +X /bin/docker-entrypoint.sh
ENTRYPOINT [ "/bin/docker-entrypoint.sh" ]

# Add healthcheck script
ADD ./bin/healthcheck.sh /bin/healthcheck.sh
RUN chmod +X /bin/healthcheck.sh
HEALTHCHECK --interval=30s --timeout=3s CMD /bin/healthcheck.sh

# Create and set workdir
RUN mkdir -p /home/app && chown -R app:app /home/app
RUN mkdir -p /home/files && chown -R app:app /home/files
WORKDIR /home/app

# Declare volumes
VOLUME /home/app
VOLUME /home/files

# Activate non root user
USER app

EXPOSE 80
CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf" ]