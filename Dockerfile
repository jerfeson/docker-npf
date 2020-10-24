FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

#Updating operating system
RUN apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade

##Installing essential packages
RUN apt-get -y install apt-utils software-properties-common curl bash-completion vim git supervisor zip unzip

##Installing NGINX
RUN apt-get -y install nginx

##Adding PHP repository
RUN add-apt-repository -y ppa:ondrej/php && apt-get update

#Installing PHP and extensions
RUN apt-get -y install php7.3-cli php7.3-common php7.3-fpm php7.3-mysql \
php7.3-curl php7.3-dev php7.3-mbstring php7.3-gd php7.3-json php7.3-redis php7.3-xml php7.3-zip php7.3-intl

# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === 'c31c1e292ad7be5f49291169c0ac8f683499edddcfd4e42232982d0fd193004208a58ff6f353fde0012d35fdd72bc394') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

# Install xdebug
RUN pecl install xdebug

#Configuring Xdebug
RUN echo "zend_extension=/usr/lib/php/20180731/xdebug.so" >> /etc/php/7.3/fpm/php.ini
RUN echo "zend_extension=/usr/lib/php/20180731/xdebug.so" >> /etc/php/7.3/cli/php.ini

# Install redis
RUN pecl install redis

# Quality tools
RUN USERNAME=$('whoami') && composer global require squizlabs/php_codesniffer=*  phpcompatibility/php-compatibility=* \
       friendsofphp/php-cs-fixer=* phpmd/phpmd=* \
    && export PATH=/$USERNAME/.composer/vendor/bin:$PATH \
    && phpcs --config-set installed_paths /$USERNAME/.composer/vendor/phpcompatibility/php-compatibility/ \
    && phpcs -i

#Blackfire.io
RUN mkdir "/conf.d" && version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > /etc/php/7.3/fpm/conf.d/blackfire.ini

#Default operating system settings
RUN ln -f -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# Clean up
RUN rm -rf /tmp/pear \
    && apt-get purge -y --auto-remove \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ADD ./supervisor.conf /etc/supervisor.conf
## Add Scripts
ADD ./start.sh /start.sh
EXPOSE  80
STOPSIGNAL SIGTERM
#CMD ["/start.sh"]
ENTRYPOINT service php7.3-fpm start && nginx -g "daemon off;"
