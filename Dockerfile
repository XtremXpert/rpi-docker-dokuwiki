FROM resin/rpi-raspbian
MAINTAINER Benoit Vezina <benoit@xtremxpert.com>

# Set the version you want of Twiki
ENV DOKUWIKI_VERSION=2018-04-22a
ARG DOKUWIKI_CSUM=18765a29508f96f9882349a304bffc03

COPY php7.list /etc/apt/sources.list.d/

RUN gpg --keyserver pgpkeys.mit.edu --recv-key CCD91D6111A06851 && \
	gpg --armor --export CCD91D6111A06851 | apt-key add -

# Update & install packages & cleanup afterwards
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update

RUN apt-get -y upgrade

RUN apt-get -y install \
        wget \
        lighttpd \
        php-cgi \
        php-gd \
        php-ldap \
        php-curl \
        php-xml \
        php-mbstring

RUN apt-get clean autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/{apt,dpkg,cache,log}

# Download & check & deploy dokuwiki & cleanup
RUN wget -q -O /dokuwiki.tgz "http://download.dokuwiki.org/src/dokuwiki/dokuwiki-$DOKUWIKI_VERSION.tgz" && \
    if [ "$DOKUWIKI_CSUM" != "$(md5sum /dokuwiki.tgz | awk '{print($1)}')" ];then echo "Wrong md5sum of downloaded file!"; exit 1; fi && \
    mkdir /dokuwiki && \
    tar -zxf dokuwiki.tgz -C /dokuwiki --strip-components 1

# Set up ownership
RUN chown -R www-data:www-data /dokuwiki

# Configure lighttpd
ADD dokuwiki.conf /etc/lighttpd/conf-available/20-dokuwiki.conf
RUN lighty-enable-mod dokuwiki fastcgi accesslog
RUN mkdir /var/run/lighttpd && chown www-data.www-data /var/run/lighttpd

COPY docker-startup.sh /startup.sh
RUN chmod +x /startup.sh
EXPOSE 80
VOLUME ["/dokuwiki/data/","/dokuwiki/lib/plugins/","/dokuwiki/conf/","/dokuwiki/lib/tpl/","/var/log/"]

ENTRYPOINT ["/startup.sh"]
CMD ["run"]


