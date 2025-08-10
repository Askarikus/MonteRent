FROM php:8.1-fpm

RUN apt update \
    && apt install -y zlib1g-dev g++ git libicu-dev zip libzip-dev curl libpq-dev libpng-dev zip cron supervisor \
    && apt install -y libmagickwand-dev --no-install-recommends && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install intl opcache pdo pdo_pgsql pgsql \
    && pecl install apcu imagick \
    && docker-php-ext-enable apcu imagick pdo_pgsql \
    && docker-php-ext-configure zip \
    && docker-php-ext-install zip

RUN apt update && apt install -y libgd-dev libfreetype6-dev --no-install-recommends \
    && docker-php-ext-configure gd --enable-gd --with-freetype \
    && docker-php-ext-install gd \
    && docker-php-ext-enable gd

RUN pecl install redis \
    && docker-php-ext-enable redis

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions amqp-1.11.0

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN curl -sS https://get.symfony.com/cli/installer | bash && \
    mv /root/.symfony5/bin/symfony /usr/local/bin/symfony

ADD ./error_reporting.ini /usr/local/etc/php/conf.d/error_reporting.ini

RUN mkdir -p /var/log/supervisor \
  && mkdir -p /etc/supervisor/conf.d

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY cronjobs /etc/cron.d/cronjobs

# RUN chmod 0644 /etc/cron.d/cronjobs && \
#    crontab /etc/cron.d/cronjobs && \
#    touch /var/log/cron.log

EXPOSE 9000
WORKDIR /var/www/monte-rent
# ENTRYPOINT ["/usr/bin/supervisord"]
