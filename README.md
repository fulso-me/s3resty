<div align="center">
<a href="https://github.com/fulso-me/s3resty"><img src="https://git.fulso.me/lorx/s3resty/badges/master/pipeline.svg?key_text=Build" alt="Master"></a>
<a href="https://hub.docker.com/repository/docker/fulsome/s3resty"><img src="https://img.shields.io/badge/-DockerHub-blue" alt="DockerHub"></a>
</div>

# What is this?

This is a distroless container for nginx with the s3 module, and lua support.
It will cache hosted files locally once requested so it can scale.
It is designed to be completely stateless.

# How do I use this?

All temporary data is stored in `/data`, including logs and caches if you'd
like to persist them. Please place your config file at `/nginx.conf`.
The container starts with `CMD [ "/nginx", "-c", "/nginx.conf" ]`

``` conf
# worker_processes 1;
# pid logs/nginx.pid;
daemon off;

# events {
# 	worker_connections 768;
# }

http {
  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  # keepalive_requests 100;
  # keepalive_timeout 65;
  types_hash_max_size 2048;
  server_names_hash_bucket_size 64;
  
  include /mime.types;
  default_type text/html;
  
  access_log /data/logs/access.log;
  error_log  /data/logs/error.log;
  
  gzip on;
  gzip_disable "msie6";
  gzip_http_version 1.1;
  gzip_types text/html text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;

  proxy_cache_lock on;
  proxy_cache_lock_timeout 60s;
  proxy_cache_path /data/cache levels=1:2 keys_zone=s3cache:10m max_size=30g;

  server {
    listen     8000;

    location / {
      set $s3_bucket        'MYBUCKETHOST';
      set $url_full         '$1';
      rewrite /$ "${uri}index.html" break;

      aws_access_key MYKEY;
      aws_secret_key MYSECRET;
      s3_bucket MYBUCKET;

      proxy_http_version     1.1;
      proxy_set_header       Host $s3_bucket;
      proxy_set_header Authorization $s3_auth_token;
      proxy_set_header x-amz-date $aws_date;
      proxy_hide_header      x-amz-id-2;
      proxy_hide_header      x-amz-request-id;
      proxy_hide_header      x-amz-meta-server-side-encryption;
      proxy_hide_header      x-amz-server-side-encryption;
      proxy_hide_header      Set-Cookie;
      proxy_ignore_headers   Set-Cookie;
      proxy_intercept_errors on;

      resolver               8.8.4.4 8.8.8.8 valid=300s;
      resolver_timeout       10s;
      proxy_pass             http://$s3_bucket$url_full;

      proxy_cache        s3cache;
      proxy_cache_valid  200 302  24h;
    }

   location = /test {
    default_type "text/plain";
    client_max_body_size 128k;
    client_body_buffer_size 128k;

    content_by_lua_block {
      ngx.say("Test page");
    }
  }
}
```

You must change:
* MYBUCKETHOST
* MYKEY
* MYSECRET
* MYBUCKET

You probably want to change:
* Standard nginx options like `worker_processes` and `worker_connections`
* The `rewrite /$` line is designed for a top level domain. If you'd like to
  use a subdomain you'll have to fix it.
* `proxy_pass` will also have to change depending on how your file structure is
  laid out.
* `proxy_chache_valid` can be changed if you'd like something different from `24h`

Anything that is commented out should have the default value.
