# Simple DNS (bind) configuration in Docker

Sometimes there is a need to expose selected internal IPs assigned by Docker. This bind deployment provides this feature. Domain names to be provided in such configuration must be listed in `/etc/bind/docker.config` file. Each line of this file should consist of three elements:
* Name to lookup in Docker envirement (optionaly it can be plain IPv4 if known);
* Subdomain to pubilsh in DNS;
* Zone to publish in DNS.

Example content of `/etc/bind/docker.config`:
```
1.1.1.1                     ns                  example.com.
container-name-example-1.   example-1           example.com.
container-name-example-2.   example-2           example.com.
container-name-example-3.   example-3           example.com.
```
Note: Definition of *ns.example.com* is mandatory as DNS server A record. 

In example above *example-1.example.com* domain will provide internal IPv4 address of *container-name-example-1* container.

Note: DNS server must *see* containers mentioned in first column, so it must be attached to the same network.

## Usage (regular)

In order to prepare configuration, build docker image and run container:
* Run `./build.sh`.
* Run container using command provided.

## Usage (with Docker secrets)

In order to prepare configuration with Docker configs (only in Docker swarm mode) and build docker image and run service:
* Create file `docker.config`.
* Run `./build.sh dns-`.The second parameter is a config names prefix (in this example all config name will start with *dns-*).
* Create config using command provided.
* Run service using command provided.

## Depedences
* Docker
