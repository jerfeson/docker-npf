FROM ubuntu:20.04

#Sem interação humana
ARG DEBIAN_FRONTEND=noninteractive

#Updating operating system
RUN apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade

##Installing essential packages
RUN apt-get -y install apt-utils software-properties-common curl bash-completion vim git zip unzip

##Installing NGINX
RUN apt-get -y install nginx

##Adding PHP repository
RUN add-apt-repository -y ppa:ondrej/php && apt-get update

#Installing PHP and extensions
RUN apt-get -y install php7.4-cli php7.4-common php7.4-fpm php7.4-mysql \
php7.4-curl php7.4-dev php7.4-mbstring php7.4-gd php7.4-json php7.4-redis php7.4-xml php7.4-zip php7.4-intl

# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === 'c31c1e292ad7be5f49291169c0ac8f683499edddcfd4e42232982d0fd193004208a58ff6f353fde0012d35fdd72bc394') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

# Install xdebug and redis
RUN pecl install xdebug redis

#Configuring Xdebug
RUN echo "zend_extension=/usr/lib/php/20180731/xdebug.so" >> /etc/php/7.4/fpm/php.ini
RUN echo "zend_extension=/usr/lib/php/20180731/xdebug.so" >> /etc/php/7.4/cli/php.ini

# Clean up
RUN rm -rf /tmp/pear \
    && apt-get purge -y --auto-remove \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE  80

CMD service php7.4-fpm start && nginx -g "daemon off;"