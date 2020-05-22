FROM ubuntu:18.04

#Atualizando sistema operacional
RUN apt-get update && apt -y upgrade && apt-get -y dist-upgrade

##Instalando pacotes essenciais
RUN apt-get -y install software-properties-common curl bash-completion vim git

#Configurações padrão do sistema operacional
RUN ln -f -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

##Instalando NGINX
RUN apt-get -y install nginx

##Adicionando repositório do PHP
RUN add-apt-repository -y ppa:ondrej/php && apt update

#Instalando PHP e extensões
RUN apt-get -y install php7.3-cli php7.3-common php7.3-fpm php7.3-mysql \
php7.3-curl php7.3-dev php7.3-mbstring php7.3-gd php7.3-json php7.3-redis php7.3-xml php7.3-zip

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install xdebug
RUN pecl install xdebug

#Configurando Xdebug
RUN echo "zend_extension=/usr/lib/php/20180731/xdebug.so" >> /etc/php/7.3/fpm/php.ini
RUN echo "zend_extension=/usr/lib/php/20180731/xdebug.so" >> /etc/php/7.3/cli/php.ini

# Install redis
RUN pecl install redis

#Configurando Redis para regenciar as sessões
RUN echo "[Session]" >> /etc/php/7.3/fpm/php.ini
RUN echo "session.save_handler = redis" >> /etc/php/7.3/fpm/php.ini
RUN echo "session.save_path = tcp://redis:6379" >> /etc/php/7.3/fpm/php.ini

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

EXPOSE  80

STOPSIGNAL SIGTERM

CMD service php7.3-fpm start && nginx -g "daemon off;"