FROM php:8.1-apache

RUN apt-get update

# development packages
RUN apt-get install -y \
    zip \
    curl \
    gnupg \
    sudo \
    unzip \
    supervisor \
    mc \
    libicu-dev \
    libxml2-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
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
    gd \
    soap \
    exif \
    pdo \
    pdo_mysql \
    zip

RUN pecl install imagick && docker-php-ext-enable imagick

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

ARG INSTALL_CRON=false
#CRON
COPY ./config/schelduler-cron /etc/cron.d/schelduler-cron
RUN chmod 0644 /etc/cron.d/schelduler-cron
RUN touch /var/log/cron.log

RUN if [ ${INSTALL_CRON} = true ]; then \
    crontab /etc/cron.d/schelduler-cron \
;fi

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