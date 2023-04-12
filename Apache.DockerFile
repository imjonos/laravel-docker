FROM php:8.1-apache

RUN apt-get update

# development packages
RUN apt-get install -y \
    zip \
    curl \
    cron \
    gnupg \
    sudo \
    unzip \
    supervisor \
    libicu-dev \
    libxml2-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libjpeg62-turbo-dev \
    libzip-dev\
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    libcurl4-openssl-dev \
    libmagickwand-dev \
    openssh-server \
    libssl-dev \
    libonig-dev \
    iproute2 \
    g++

RUN a2enmod rewrite headers

RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install -j$(nproc) gd

RUN docker-php-ext-install \
    bz2 \
    intl \
    iconv \
    bcmath \
    pcntl \
    opcache \
    curl \
    calendar \
    mbstring \
    soap \
    exif \
    pdo \
    pdo_mysql \
    zip

RUN pecl install imagick && docker-php-ext-enable imagick

ARG INSTALL_MC=false
# Install MC

RUN if [ ${INSTALL_MC} = true ]; then \
    apt-get install -y mc \
;fi

ARG INSTALL_XDEBUG=false
# Install xdebug

RUN if [ ${INSTALL_XDEBUG} = true ]; then \
    pecl install xdebug && docker-php-ext-enable xdebug \
;fi

RUN pecl install -o -f redis \
&&  rm -rf /tmp/pear \
&&  docker-php-ext-enable redis

COPY ./config/xdebug.ini  /usr/local/etc/php/conf.d/
COPY ./config/php.ini /usr/local/etc/php/php.ini

# Virtual Host
RUN mkdir /var/www/localhost
COPY ./config/host.conf /etc/apache2/sites-available/host.conf
RUN rm -rfv /etc/apache2/sites-enabled/*.conf
RUN ln -s /etc/apache2/sites-available/host.conf /etc/apache2/sites-enabled/host.conf

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer self-update

# Add user
ARG USER=docker
ARG UID=1000
ARG GID=1000
# Default password for user
ARG PW=docker
# Option1: Using unencrypted password/ specifying password
RUN useradd -m ${USER} -s /bin/bash --uid=${UID} && echo "${USER}:${PW}" | chpasswd
RUN ln -s /var/www/localhost /home/docker/html

#HORIZON
COPY ./config/horizon.conf /etc/supervisor/conf.d/horizon.conf

ARG INSTALL_SSH=false
# Install ssh-server
RUN  if [ ${INSTALL_SSH} = true ]; then \
    apt-get install -y openssh-server && adduser ${USER} sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
;fi

ARG INSTALL_SUPERVISOR=true
# supervisor install
RUN  if [ ${INSTALL_SUPERVISOR} = true ]; then \
    apt-get install -y supervisor \
;fi

ARG INSTALL_CRON=false
#CRON
COPY ./config/schelduler-cron /etc/cron.d/schelduler-cron
RUN chmod 0644 /etc/cron.d/schelduler-cron
RUN touch /var/log/cron.log

RUN if [ ${INSTALL_CRON} = true ]; then \
    crontab /etc/cron.d/schelduler-cron \
;fi

ARG INSTALL_TYPE=hosted
RUN mkdir /var/www/tmp
COPY ./source /var/www/tmp

ENV APP_URL=http://localhost:8081
ENV DB_HOST=mariadb
ENV DB_PORT=3306
ENV DB_DATABASE=docker
ENV DB_USERNAME=docker
ENV DB_PASSWORD=docker

RUN if [ "${INSTALL_TYPE}" = standalone ]; then \
    cp -r /var/www/tmp/* /var/www/localhost && \
    cp /var/www/tmp/production.env /var/www/localhost/.env \
;fi
RUN rm -rf /var/www/tmp

# SSH
RUN mkdir /var/run/sshd

ARG ROOT_PW=docker
RUN echo 'root:${ROOT_PW}'
RUN echo 'root:${ROOT_PW}' | chpasswd

EXPOSE 22
EXPOSE 80
EXPOSE 443
EXPOSE 7080

COPY start.sh /usr/local/bin/
RUN chmod 0755 /usr/local/bin/start.sh

ENV IS_SSH=${INSTALL_SSH}
ENV IS_CRON=${INSTALL_CRON}
ENV IS_SUPERVISOR=${INSTALL_SUPERVISOR}


ENTRYPOINT start.sh "$IS_SSH" "$IS_CRON" "$IS_SUPERVISOR" && bash
