# syntax=docker/dockerfile:1

ARG ELIXIR_VERSION=1.15.7
ARG OTP_VERSION=26.2.5
ARG DEBIAN_VERSION=bookworm-20240311

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION} AS build

RUN apt-get update -y && apt-get install -y build-essential git curl ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only prod && mix deps.compile

COPY assets assets
COPY lib lib
COPY priv priv
COPY rel rel

RUN mix assets.deploy
RUN mix compile
RUN mix release

FROM debian:bookworm-20240311-slim AS app

RUN apt-get update -y && apt-get install -y ca-certificates libstdc++6 openssl libncurses6 locales && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LANG=C.UTF-8
WORKDIR /app

RUN useradd -r -u 1000 -g root -d /app prayer_app && chown -R prayer_app:root /app

COPY --from=build --chown=prayer_app:root /app/_build/prod/rel/prayer_app ./

USER prayer_app

CMD ["/bin/sh", "/app/bin/server"]