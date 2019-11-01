FROM php:7.2-apache

RUN apt-get update

# development packages
RUN apt-get install -y \
    git \
    zip \
    curl \
    gnupg \
    sudo \
    unzip \
    mc \
    libicu-dev \
    libxml2-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    openssh-server \
    g++

RUN apt-get install -y libatk-bridge2.0-0 gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget

RUN curl -sL https://deb.nodesource.com/setup_13.x  | bash -
RUN apt-get -y install nodejs


RUN a2enmod rewrite headers

RUN docker-php-ext-install \
    bz2 \
    intl \
    iconv \
    bcmath \
    opcache \
    calendar \
    mbstring \
    gd \
    soap \
    exif \
    pdo \
    pdo_mysql \
    zip

# Install xdebug
RUN pecl install xdebug-2.6.0 && docker-php-ext-enable xdebug
COPY ./config/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/

# composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Virtual Host
RUN mkdir /var/www/localhost
COPY ./config/host.conf /etc/apache2/sites-available/host.conf
RUN rm -rfv /etc/apache2/sites-enabled/*.conf
RUN ln -s /etc/apache2/sites-available/host.conf /etc/apache2/sites-enabled/host.conf

# Add user
ARG USER=docker
ARG UID=1000
ARG GID=1000
# default password for user
ARG PW=docker
# Option1: Using unencrypted password/ specifying password
RUN useradd -m ${USER} -s /bin/bash --uid=${UID} && echo "${USER}:${PW}" | chpasswd
RUN adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# SSH
RUN mkdir /var/run/sshd
RUN echo 'root:123456' | chpasswd

EXPOSE 22
EXPOSE 80
EXPOSE 443
EXPOSE 9000

#CMD ["/usr/sbin/sshd", "-D"]
#CMD ["/usr/sbin/apachectl","-D","FOREGROUND"]

ENTRYPOINT sudo service ssh restart && sudo service apache2 restart && bash
