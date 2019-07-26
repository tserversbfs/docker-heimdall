FROM lsiobase/cloud9:files-alpine as c9files
FROM lsiobase/nginx:3.10

# set version label
ARG BUILD_DATE
ARG VERSION
ARG HEIMDALL_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment settings
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

# cloud9
COPY --from=c9files /buildout/ /

RUN \
 echo "**** install dev packages ****" && \
 apk add --no-cache \
	c-ares \
	curl \
	git \
	gnupg \
	http-parser \
	libevent \
	libevent \
	libstdc++ \
	libuv \
	sudo && \
 echo "****  user perms ****" && \
 usermod -aG wheel \
	abc && \
 echo "auth       sufficient   pam_shells.so" > /etc/pam.d/chsh && \
 chsh abc -s /bin/bash && \
 sed -e \
	's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' \
	-i /etc/sudoers && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache \
	curl \
	php7-ctype \
	php7-pdo_sqlite \
	php7-tokenizer \
	php7-zip \
	tar && \
 echo "**** install heimdall ****" && \
 mkdir -p \
	/c9sdk/build/standalone \
	/var/www/localhost/heimdall && \
 git clone \
	https://github.com/linuxserver/Heimdall.git \
	/var/www/localhost/heimdall && \
 echo "**** dev setup and permissions ****" && \
 echo -e \
	'\n# Heimdall user authorization\nfastcgi_param  PHP_AUTH_USER $remote_user;\nfastcgi_param  PHP_AUTH_PW $http_authorization;' >> \
        /etc/nginx/fastcgi_params && \
 cp \
        /var/www/localhost/heimdall/.env.example \
        /var/www/localhost/heimdall/.env && \
 php /var/www/localhost/heimdall/artisan key:generate && \
 sed -i \
	's/QUEUE_DRIVER=sync/QUEUE_DRIVER=database/' \
	/var/www/localhost/heimdall/.env && \
 chown -R abc:abc \
	/c9sdk/build/standalone \
	/c9bins \
	/config \
	/var/www/localhost/heimdall && \
 echo "**** cleanup ****" && \
 rm -rf \
	/tmp/*

# add local files
COPY root/ /
