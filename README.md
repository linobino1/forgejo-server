# Forgejo Server

this is my setup for a Forgejo instance running on docker compose with a Traefik proxy.

## Runner Installation

### Set up a runner on another VM/VPS

1. spin up a new ubuntu machine and install docker
1. Follow the "binary installation" guide from the [Forgejo Docs](https://forgejo.org/docs/latest/admin/actions/runner-installation/#downloading-and-installing-the-binary)
    - make sure to replace the architecture with `arm64` if applicable
    - you might have to remove the brackets from the ${RUNNER_VERSION} variables
1. Modify the config to use Docker from the host as described in the [docs](https://forgejo.org/docs/latest/admin/actions/runner-installation/#configuration)
    1. `forgejo-runner generate-config > config.yml`
    1. edit `config.yml`, set `container.docker_host = "automount"`
    1. move the `config.yml` to `/etc/forgejo-runner/config.yml`
1. Create and start a systemd service for the runner as explained in the [Forgejo Docs](https://forgejo.org/docs/latest/admin/actions/runner-installation/#running-as-a-systemd-service) and modify the start command by adding `--config /etc/forgejo-runner/config.yml`

