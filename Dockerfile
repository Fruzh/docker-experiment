FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libzip-dev zip unzip git curl libonig-dev libxml2-dev \
    && docker-php-ext-install pdo_mysql mbstring zip bcmath \
    && a2enmod rewrite

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/000-default.conf \
    && echo '<Directory /var/www/html/public>\n\
    AllowOverride All\n\
</Directory>' >> /etc/apache2/apache2.conf

WORKDIR /var/www/html
COPY --chown=www-data:www-data . .

RUN chmod -R 775 storage bootstrap/cache

CMD php artisan config:clear && \
    php artisan key:generate && \
    php artisan storage:link && \
    php artisan migrate --force && \
    apache2-foreground

EXPOSE 80