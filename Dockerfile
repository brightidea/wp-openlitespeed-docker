FROM litespeedtech/openlitespeed:latest

WORKDIR /usr/local/lsws/
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update && apt-get upgrade -y && apt-get install -y wget

# Installing wordpress
RUN wget --no-check-certificate http://wordpress.org/latest.tar.gz
RUN tar -xzvf latest.tar.gz  >/dev/null 2>&1
RUN rm latest.tar.gz
RUN wget -q -r --level=0 -nH --cut-dirs=2 --no-parent https://plugins.svn.wordpress.org/litespeed-cache/trunk/ --reject html -P ./wordpress/wp-content/plugins/litespeed-cache/
RUN chown -R --reference=./autoupdate ./wordpress

#
RUN rm -rf /usr/local/lsws/conf/httpd_config.conf /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini /var/lib/apt/lists/* ./enable_lst_debain_repo.sh /usr/local/lsws/conf/vhosts/Example && apt-get remove --purge -y wget

RUN touch /usr/local/lsws/logs/error.log \
    && touch /usr/local/lsws/logs/access.log \
    # && ln -sf /dev/stdout /usr/local/lsws/logs/access.log \
    # && ln -sf /dev/stderr /usr/local/lsws/logs/error.log \
    && ln -sf /usr/local/lsws/lsphp74/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp \
    && ln -sf /usr/local/lsws/lsphp74/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp7

COPY ./config/httpd_config.conf /usr/local/lsws/conf/
COPY ./config/php.ini /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/
COPY ./config/entrypoint.sh /

RUN chmod +x /entrypoint.sh

VOLUME ["/usr/local/lsws/wordpress"]

EXPOSE 80
EXPOSE 443
EXPOSE 443/udp
EXPOSE 7080
EXPOSE 7080/udp

ENV PATH=/usr/local/lsws/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    DB_NAME='wordpress' \
    DB_USERNAME='root' \
    DB_PASSWORD='' \
    DB_HOST='localhost' \
    SERVER_EMAIL='info@localhost' \
    SERVER_LOGIN='admin' \
    SERVER_PASSWORD='123456' \
    SSL_COUNTRY='US' \
    SSL_STATE='New Jersey' \
    SSL_LOCALITY='Virtual' \
    SSL_ORG='LiteSpeedCommunity' \
    SSL_ORGUNIT='Testing' \
    SSL_HOSTNAME='webadmin' \
    SSL_EMAIL='.' \
    WORDPRESS_TABLE_PREFIX='wp_' \
    WORDPRESS_DEBUG='false' \
    WORDPRESS_CACHE='false' \
    PHP_MEMORY_LIMIT='512M' \
    PHP_MAX_EXECUTION_TIME='1800' \
    PHP_POST_MAX_SIZE='2048M' \
    PHP_UPLOAD_MAX_FILESIZE='2048M' \
    DOMAIN_URL='*' \
    PROTOCOL='https' \
    WPPORT='80' \
    SSLWPPORT='443' \
    OLS_DEBUG_LEVEL='0' \
    OLS_MAX_REQ_BODY_SIZE='2047M' \
    OLS_MAX_DYN_RESP_SIZE='2047M' \
    CORS_HEADER='' \
    LOG_DEBUG='0'

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail -f /usr/local/lsws/logs/access.log | sed 's/^/[LOG: ]/' & tail -f /usr/local/lsws/logs/error.log | sed 's/^/[ERROR: ]/'"]

# [supervisord]
# nodaemon=true

# [program:startup]
# priority=1
# command=/root/credentialize_and_run.sh
# stdout_logfile=/var/log/supervisor/%(program_name)s.log
# stderr_logfile=/var/log/supervisor/%(program_name)s.log
# autorestart=false
# startsecs=0

# [program:nginx]
# priority=10
# command=nginx -g "daemon off;"
# stdout_logfile=/var/log/supervisor/nginx.log
# stderr_logfile=/var/log/supervisor/nginx.log
# autorestart=true

# CMD ["/usr/bin/supervisord", "-n"]
