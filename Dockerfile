FROM ubuntu:20.04

#Sem interação humana
ARG DEBIAN_FRONTEND=noninteractive

#Updating operating system
RUN apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade

##Installing essential packages
RUN apt-get -y install apt-utils software-properties-common curl bash-completion vim git zip unzip

#Installing NGINX
RUN apt-get -y install nginx

##Adding PHP repository
RUN add-apt-repository -y ppa:ondrej/php && apt-get update

#Installing PHP and extensions
RUN apt-get -y install php7.4 php7.4-redis php7.4-fpm php7.4-common php7.4-curl  \
php7.4-dev php7.4-mbstring php7.4-gd php7.4-json php7.4-redis php7.4-xml php7.4-zip php7.4-intl


# Install xdebug and redis
RUN pecl install xdebug redis

#Configuring Xdebug
RUN echo "zend_extension=/usr/lib/php/20190902/xdebug.so" >> /etc/php/7.4/fpm/php.ini
RUN echo "zend_extension=/usr/lib/php/20190902/xdebug.so" >> /etc/php/7.4/cli/php.ini

RUN apt-get install -y composer

# Clean up
RUN rm -rf /tmp/pear \
    && apt-get purge -y --auto-remove \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE  80

CMD service php7.4-fpm start && nginx -g "daemon off;"