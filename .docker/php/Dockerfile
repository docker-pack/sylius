ARG PHP_VERSION=7.4.3
FROM php:${PHP_VERSION}-apache AS sylius_php
ARG WITH_OPCACHE=${WITH_OPCACHE:-}

LABEL Description="Sylius Easy installer " \
      maintainer="DAIF Abderrhaman <daif.abderrahman@gmail.com>"

# Install all dependencies
RUN apt-get update && apt-get upgrade -y apt-utils && \
    apt-get install -y --no-install-recommends git \
    ssh \
    nano \
    tree \
    vim \
    curl \
    ftp \
    wget \
    unzip \
    zip \
    gnupg \
    libc-client-dev \
    libkrb5-dev \
    zlib1g-dev \
    libzip-dev \
    libxml2-dev \
    libmagickwand-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libssl-dev && \
    docker-php-ext-install json && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-install imap && \
    docker-php-ext-install zip && \
    docker-php-ext-install dom && \
    docker-php-ext-install bcmath && \
    docker-php-ext-install intl &&\
    docker-php-ext-install exif &&\
    curl -sL https://deb.nodesource.com/setup_12.x | /bin/bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g n && \
    n 12.14.1 && \
    npm install -g yarn

RUN docker-php-ext-install -j$(nproc) gd && \
    docker-php-ext-install ftp && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"; \
    php -r "if (hash_file('sha384', 'composer-setup.php') === $(curl https://composer.github.io/installer.sig)) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"; \
    php composer-setup.php --install-dir /usr/local/bin --filename=composer --version=2.0.8; \
    php -r "unlink('composer-setup.php');"; \
    apt-get purge -y --auto-remove && \
    apt-get clean

# Install Postgre PDO
RUN apt-get install -y libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install opcache pdo pdo_pgsql pgsql

RUN set -ex; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		imagemagick \
		less \
		mariadb-client msmtp \
		libc-client-dev \
		libfreetype6-dev \
		libjpeg-dev \
		libjpeg62-turbo-dev \
		libkrb5-dev \
		libmagickwand-dev \
		libmcrypt-dev \
		libicu-dev \
		libmemcached-dev \
		libxml2-dev \
		libpng-dev \
		libzip-dev \
		libssl-dev \
		unzip \
		vim \
		zip

RUN pecl install imagick; \
	pecl install memcached; \
	pecl install mcrypt-1.0.3; \
	pecl install redis; \
	docker-php-ext-configure gd --with-freetype --with-jpeg; \
	docker-php-ext-configure zip; \
	docker-php-ext-install gd; \
	PHP_OPENSSL=yes docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
	echo "extension=memcached.so" >> /usr/local/etc/php/conf.d/memcached.ini; \
	docker-php-ext-install imap; \
	docker-php-ext-install mysqli; \
	docker-php-ext-install pdo_mysql; \
	docker-php-ext-install opcache; \
	docker-php-ext-install soap; \
	docker-php-ext-install intl; \
	docker-php-ext-install zip; \
	docker-php-ext-install exif; \
	docker-php-ext-enable imagick mcrypt redis; \
	docker-php-ext-install bcmath; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*;

### apcu
RUN if [ "$WITH_OPCACHE" == "1" ]; \
    then docker-php-source extract \
    && pecl install apcu-5.1.18 \
    && docker-php-ext-enable apcu \
    && docker-php-source delete; \
    fi


RUN a2enmod rewrite
RUN a2enmod proxy_fcgi ssl rewrite proxy proxy_balancer proxy_http proxy_ajp headers
RUN echo 'Header always set Access-Control-Allow-Origin "*"' >> /etc/apache2/apache2.conf
RUN echo 'Header always set KeepAlive On' >> /etc/apache2/apache2.conf
RUN echo 'Header always set Access-Control-Allow-Methods "POST, GET, OPTIONS, DELETE, PUT, PATCH"' >> /etc/apache2/apache2.conf
RUN echo 'Header always set Access-Control-Max-Age "1000"' >> /etc/apache2/apache2.conf
RUN echo 'Header always set Access-Control-Allow-Headers "x-requested-with, Content-Type, origin, authorization, accept, client-security-token"' >> /etc/apache2/apache2.conf

#override some php configurations
COPY php.ini /usr/local/etc/php/php.ini
COPY opcache.ini /etc/php/${PHP_VERSION}/conf.d/opcache.ini

COPY 000-default.conf  /etc/apache2/sites-enabled/000-default.conf

WORKDIR /var/www

CMD ["apache2-foreground"]

EXPOSE 80 443
