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
RUN apt-get -y install php7.3-cli php7.3-common php7.3-fpm php7.3-mysql \
php7.3-curl php7.3-dev php7.3-mbstring php7.3-gd php7.3-json php7.3-redis php7.3-xml php7.3-zip php7.3-intl

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install xdebug and redis
RUN pecl install xdebug redis

#Configuring Xdebug
RUN echo "zend_extension=/usr/lib/php/20180731/xdebug.so" >> /etc/php/7.3/fpm/php.ini
RUN echo "zend_extension=/usr/lib/php/20180731/xdebug.so" >> /etc/php/7.3/cli/php.ini


# Clean up
RUN rm -rf /tmp/pear \
    && apt-get purge -y --auto-remove \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE  80

CMD service php7.3-fpm start && nginx -g "daemon off;"