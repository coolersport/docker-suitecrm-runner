FROM php:7.2.12-apache-stretch

COPY entrypoint.sh php.custom.ini /

# update and install required tools
RUN apt update && \
    apt upgrade -y && \
    apt install -y git netcat zip unzip \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        zlib1g-dev \
        libc-client-dev \
        libkrb5-dev \
        libldap2-dev \
        cron && \
# run on non-privilege ports
    sed -i 's/Listen 80$/Listen 8080/g' /etc/apache2/ports.conf && \
    sed -i 's/Listen 443$/Listen 8443/g' /etc/apache2/ports.conf && \
    rm -rf /var/log/apache2/* && \
    touch /var/log/apache2/access.log /var/log/apache2/error.log /var/log/apache2/other_vhosts_access.log && \
    chown -R www-data:www-data /var/log/apache2 && \
# install gosu
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    curl -fsLo /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.10/gosu-$dpkgArch" && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
# install composer
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    #php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer && \
# install required modules
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install -j$(nproc) zip \
        opcache \
        pdo_mysql \
        mysqli \
        zip \
        gd \
        fileinfo \
        soap \
        imap \
        ldap && \
    ln -s /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load && \
# custom php configurations
    mv /php.custom.ini /usr/local/etc/php/conf.d/ && \
# entrypoint
    chmod +x /entrypoint.sh && \
# cleanup
    find /var/www/html -type d -name .git -prune -exec rm -rf {} ';' && \
    apt remove -y git && \
    apt autoremove -y && \
    apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
CMD ["gosu","www-data","apache2-foreground"]
