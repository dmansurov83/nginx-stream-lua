FROM debian:stretch

RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y wget libpcre3-dev build-essential libssl-dev zlib1g-dev luajit && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN wget http://nginx.org/download/nginx-1.13.0.tar.gz \
    && wget http://luajit.org/download/LuaJIT-2.0.3.tar.gz \
    && wget -O nginx_devel_kit.tar.gz https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz \
    && wget -O nginx_lua_module.tar.gz https://github.com/openresty/lua-nginx-module/archive/v0.10.15.tar.gz \
    && tar xvf LuaJIT-2.0.3.tar.gz \
    && tar xvf nginx_devel_kit.tar.gz \
    && tar xvf nginx_lua_module.tar.gz \
    && tar -zxvf nginx-1.*.tar.gz \
    && cd LuaJIT-2.0.3 \
    && make install \
    && cd .. \
    && cd nginx-1.* \
    && LUAJIT_LIB=/usr/local/lib LUAJIT_INC=/usr/local/include/luajit-2.0 \
    ./configure --prefix=/opt/nginx \
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --with-ipv6 \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --add-module=/opt/ngx_devel_kit-0.3.0 \
        --add-module=/opt/lua-nginx-module-0.10.15 \
    && make && make install \
    && cd .. \
    && rm -rf nginx-1.* \
    && rm -rf LuaJIT-* \
    && rm -rf ngx_devel_kit* \
    && rm -rf lua-nginx-module*

RUN find . -path '/usr/local/lib/libluajit*' 
RUN ln -s /usr/local/lib/libluajit-5.1.so.2.0.3 /usr/lib/libluajit-5.1.so.2

# nginx user
RUN adduser --system --no-create-home --disabled-login --disabled-password --group nginx

# config dirs
RUN mkdir /opt/nginx/http.conf.d && mkdir /opt/nginx/stream.conf.d

ADD nginx.conf /opt/nginx/conf/nginx.conf
ADD zero_downtime_reload.sh /opt/nginx/sbin/zero_downtime_reload.sh

WORKDIR /

EXPOSE 80 443

CMD ["/opt/nginx/sbin/nginx", "-g", "daemon off;"]
