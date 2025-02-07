ARG ELIXIR_VERSION=1.13.4
ARG OTP_VERSION=25.0.2
ARG DEBIAN_VERSION=bullseye-20210902-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder

RUN apt-get update -y && apt-get install -y erlang-ssl erlang-inets libz-dev libyaml-cpp-dev libssl-dev libyaml-dev libpython2.7-dev build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV="prod"

COPY mix.exs mix.lock ./

RUN mix deps.get --only $MIX_ENV --no-archives-check

RUN mkdir config

RUN mix deps.update fast_xml

COPY config/config.exs config/${MIX_ENV}.exs config/
COPY config/_DO_NOT_TOUCH_ejabberd.yml config/_DO_NOT_TOUCH_ejabberd.yml config/
COPY certs/private.key certs/private.key
COPY certs/ca_bundle.crt certs/ca_bundle.crt
COPY certs/certificate.crt certs/certificate.crt
RUN mix deps.compile

COPY openssl.cnf /usr/lib/ssl/openssl.cnf

COPY lib lib
RUN mix compile

COPY config/runtime.exs config/

RUN mix release

FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y erlang-ssl erlang-inets libstdc++6 libz-dev libyaml-cpp-dev libssl-dev libyaml-dev libpython2.7-dev openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"

RUN chown -R nobody /app
ENV MIX_ENV="prod"

COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/synapse ./
COPY --from=builder --chown=nobody:root /app/config/_DO_NOT_TOUCH_ejabberd.yml ./config/_DO_NOT_TOUCH_ejabberd.yml
COPY --from=builder --chown=nobody:root /app/certs/ca_bundle.crt ./certs/ca_bundle.crt
COPY --from=builder --chown=nobody:root /app/certs/certificate.crt ./certs/certificate.crt
COPY --from=builder --chown=nobody:root /app/certs/private.key ./certs/private.key
COPY --from=builder --chown=nobody:root /usr/lib/ssl/openssl.cnf /usr/lib/ssl/openssl.cnf

USER nobody

ENV RELEASE_NODE="synapse@localhost"

CMD ["/app/bin/synapse", "start"]

