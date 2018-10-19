FROM bitwalker/alpine-elixir:1.7.3

EXPOSE 4000
ENV PORT=4000 \
    MIX_ENV=prod \
    REPLACE_OS_VARS=true \
    SHELL=/bin/bash

COPY rel ./rel
COPY config ./config
COPY lib ./lib
COPY priv ./priv
COPY mix.exs .
COPY vm.args .
RUN \
    mix do deps.get, deps.compile && \
    mix do compile, release --verbose --env=prod && \
    mkdir -p /opt/job_webserver/log && \
    cp _build/prod/rel/job_webserver/releases/0.1.0/job_webserver.tar.gz /opt/job_webserver/ && \
    cd /opt/job_webserver && \
    tar -xzf job_webserver.tar.gz && \
    rm job_webserver.tar.gz && \
    rm -rf /opt/app/* && \
    chmod -R 777 /opt/app && \
    chmod -R 777 /opt/job_webserver

WORKDIR /opt/job_webserver

USER default

ENTRYPOINT ["./bin/job_webserver"]