# Build: docker build -t simple_chat .
# Run:   docker run -e PORT=4000 -p 4000:4000 -t simple_chat

FROM bitwalker/alpine-elixir:1.12.3 as build

COPY . .

# Install Hex + Rebar
RUN mix do local.hex --force, local.rebar --force

RUN rm -Rf _build && \
    MIX_ENV=prod mix do deps.get, deps.compile, compile, release

FROM bitwalker/alpine-erlang:24.0.5

RUN apk upgrade --no-cache && \
    apk add --no-cache bash openssl libgcc libstdc++ ncurses-libs
    
COPY --from=build /opt/app/_build/prod/rel/simple_chat/ .

USER default

ENTRYPOINT ["bin/simple_chat"]
CMD ["start"]
