FROM debian:jessie as build

RUN apt-get -y update
RUN apt-get -y install curl build-essential libpcre3 libpcre3-dev zlib1g-dev libssl-dev git perl

RUN curl -LO https://openresty.org/download/openresty-1.15.8.3.tar.gz && \
    tar zxf openresty-1.15.8.3.tar.gz && \
    cd openresty-1.15.8.3 && \
    git clone -b AuthV2 https://github.com/anomalizer/ngx_aws_auth.git && \
    ./configure --with-cc-opt="-static -static-libgcc" --with-ld-opt="-static" \
    --with-http_ssl_module --add-module=ngx_aws_auth && \
    make -j1 && \
    make install

RUN mkdir -p /opt && \
    mkdir -p /opt/data/cache && \
    mkdir -p /opt/data/logs && \
    mkdir -p /opt/usr/local/nginx/conf && \
    mkdir -p /opt/usr/local/nginx/logs && \
    cp -a /usr/local/openresty/bin/openresty /opt/openresty && \
    cp -a /usr/local/openresty/nginx/conf/mime.types /opt/mime.types && \
    cp -a --parents /usr/local/openresty/ /opt && \
    cp -a --parents /etc/passwd /opt && \
    cp -a --parents /etc/group /opt

# RUN cp -a /opt/mime.types /mime.types
# RUN mkdir -p /data/cache && \
#     mkdir -p /data/logs && \
#     mkdir -p /usr/local/nginx/logs

# ENV PATH=/home/lorx/perl5/bin:/home/lorx/slackbin:/home/lorx/.bin:/home/lorx/.go/bin:/opt/hfs13.0.509/bin/:/home/lorx/.bin-sym:/home/lorx/.local/bin:/home/lorx/.gem/ruby/2.7.0/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/opt/cuda/bin:/usr/lib/go/bin:/home/lorx/go/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/home/lorx/._configs/config/nvim/plugged/fzf/bin:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

# CMD [ "/usr/local/openresty/bin/openresty", "-c", "/nginx.conf" ]

FROM gcr.io/distroless/base
LABEL Maintainer="Brian Robertson <brian@fulso.me>" \
      Description="Distroless OpenResty with S3"

COPY --from=build /opt /

ENV PATH=/home/lorx/perl5/bin:/home/lorx/slackbin:/home/lorx/.bin:/home/lorx/.go/bin:/opt/hfs13.0.509/bin/:/home/lorx/.bin-sym:/home/lorx/.local/bin:/home/lorx/.gem/ruby/2.7.0/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/opt/cuda/bin:/usr/lib/go/bin:/home/lorx/go/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/home/lorx/._configs/config/nvim/plugged/fzf/bin:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

CMD [ "/openresty", "-c", "/nginx.conf" ]

# vim: set filetype=dockerfile :
