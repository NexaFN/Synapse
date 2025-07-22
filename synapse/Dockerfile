ARG ELIXIR_VERSION=1.13.4
ARG OTP_VERSION=25.0.2
ARG DEBIAN_VERSION=bullseye-20210902-slim
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        erlang-ssl \
        erlang-inets \
        libz-dev \
        libyaml-cpp-dev \
        ejabberd \
        libssl-dev \
        libyaml-dev \
        libpython2.7-dev \
        build-essential \
        git \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV="prod"

COPY mix.exs mix.lock ./
COPY config/config.exs config/${MIX_ENV}.exs config/_DO_NOT_TOUCH_ejabberd.yml config/

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get --only $MIX_ENV --no-archives-check && \
    mix deps.compile

COPY certs/private.key certs/ca_bundle.crt certs/certificate.crt certs/
COPY openssl.cnf /usr/lib/ssl/

COPY lib lib

RUN mix compile && \
    mix release

FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        erlang-ssl \
        erlang-inets \
        libstdc++6 \
        libz-dev \
        libyaml-cpp-dev \
        libssl-dev \
        libyaml-dev \
        libpython2.7-dev \
        openssl \
        libncurses5 \
        locales \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    MIX_ENV="prod" \
    RELEASE_NODE="synapse@localhost"

WORKDIR "/app"

RUN chown -R nobody /app

COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/synapse ./
COPY --from=builder --chown=nobody:root /app/config/_DO_NOT_TOUCH_ejabberd.yml ./config/
COPY --from=builder --chown=nobody:root /app/certs/ca_bundle.crt ./certs/
COPY --from=builder --chown=nobody:root /app/certs/certificate.crt ./certs/
COPY --from=builder --chown=nobody:root /app/certs/private.key ./certs/
COPY --from=builder --chown=nobody:root /usr/lib/ssl/openssl.cnf /usr/lib/ssl/

USER nobody

EXPOSE 5222 5269 5280

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD nc -z localhost 5222 || exit 1

ENV S_TOKEN="2gb293gh289gh2809hf28h90901opjfpo1lpjzvlkjakljflakihl"
CMD ["/app/bin/synapse", "start", "--token", "${TOKEN}"]

