# Simple Chat

Simple chat server in Elixir.\
Message wrote by any user will be sent to all other connected users.

# Usage

Build and run with the following commands.

## Build

`docker build -t simple_chat .`

## Run server

`docker run -e PORT=10000 -p 10000:10000 -t simple_chat`

## Connect
Connect to server with telnet:\
`telnet 127.0.0.1 10000`

Type `\q` to quit connection.

## Remove built docker image

`docker rmi simple_chat`

