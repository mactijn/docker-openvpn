# OpenVPN for Docker

This image will run an OpenVPN instance in Docker

## Usage

to start a new instance:

```
$ cp ca-details.example ca-details
$ vi ca-details
...
$ docker-compose run --rm openvpn init
$ docker-compose up -d
```

to add a user:

```
$ docker-compose run --rm openvpn client <clientname>
```

You can find the client config in `client-configs/files/<clientname>.ovpn`.

